require 'spec_helper'

describe Projects::IssuesController do
  include Rails.application.routes.url_helpers

  let(:namespace) { create(:group, :public) }
  let(:project)   { create(:project_empty_repo, :public, namespace: namespace) }
  let(:user) { create(:user) }

  describe 'GET #index' do
    before do
      sign_in user
      project.add_developer(user)
    end

    it_behaves_like 'unauthorized when external service denies access' do
      subject { get :index, namespace_id: project.namespace, project_id: project }
    end
  end

  describe 'POST export_csv' do
    let(:viewer)            { user }
    let(:issue)             { create(:issue, project: project) }
    let(:globally_licensed) { false }

    before do
      project.add_developer(user)

      sign_in(viewer) if viewer

      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:export_issues).and_return(globally_licensed)
    end

    def request_csv
      post :export_csv, namespace_id: project.namespace.to_param, project_id: project.to_param
    end

    context 'unlicensed' do
      it 'returns 404' do
        expect(ExportCsvWorker).not_to receive(:perform_async)

        request_csv

        expect(response.status).to eq(404)
      end
    end

    context 'globally licensed' do
      let(:globally_licensed) { true }

      it 'allows CSV export' do
        expect(ExportCsvWorker).to receive(:perform_async).with(viewer.id, project.id, anything)

        request_csv

        expect(response).to redirect_to(project_issues_path(project))
        expect(response.flash[:notice]).to match(/\AYour CSV export has started/i)
      end

      context 'anonymous user' do
        let(:project) { create(:project_empty_repo, :public, namespace: namespace) }
        let(:viewer) { nil }

        it 'redirects to the sign in page' do
          request_csv

          expect(ExportCsvWorker).not_to receive(:perform_async)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'licensed by namespace' do
      let(:globally_licensed) { true }
      let(:namespace) { create(:group, :private, plan: :bronze_plan) }
      let(:project) { create(:project, namespace: namespace) }

      before do
        stub_application_setting(check_namespace_plan: true)
      end

      it 'allows CSV export' do
        expect(ExportCsvWorker).to receive(:perform_async).with(viewer.id, project.id, anything)

        request_csv

        expect(response).to redirect_to(project_issues_path(project))
        expect(response.flash[:notice]).to match(/\AYour CSV export has started/i)
      end
    end
  end

  describe 'issue weights' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:issue) { create(:issue, project: project, weight: 5) }
    let(:issue2) { create(:issue, project: project, weight: 1) }
    let(:new_issue) { build(:issue, project: project, weight: 5) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    def perform(method, action, opts = {})
      send(method, action, opts.merge(namespace_id: project.namespace.to_param, project_id: project.to_param))
    end

    context 'licensed' do
      before do
        stub_licensed_features(issue_weights: true)
      end

      describe '#index' do
        it 'allows sorting by weight' do
          expected = [issue, issue2].sort_by(&:weight)

          perform :get, :index, sort: 'weight'

          expect(response).to have_gitlab_http_status(200)
          expect(assigns(:issues)).to eq(expected)
        end

        it 'allows filtering by weight' do
          _ = issue
          _ = issue2

          perform :get, :index, weight: 1

          expect(response).to have_gitlab_http_status(200)
          expect(assigns(:issues)).to eq([issue2])
        end
      end

      describe '#update' do
        it 'sets issue weight' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6 }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(issue.reload.weight).to eq(6)
        end
      end

      describe '#create' do
        it 'sets issue weight' do
          perform :post, :create, issue: new_issue.attributes

          expect(response).to have_gitlab_http_status(302)
          expect(Issue.count).to eq(1)

          issue = Issue.first
          expect(issue.weight).to eq(new_issue.weight)
        end
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(issue_weights: false)
      end

      describe '#index' do
        it 'ignores filtering by weight' do
          expected = [issue, issue2]

          perform :get, :index, weight: 1

          expect(response).to have_gitlab_http_status(200)
          expect(assigns(:issues)).to match_array(expected)
        end
      end

      describe '#update' do
        it 'does not set issue weight' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6 }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(issue.reload.weight).to be_nil
          expect(issue.reload.read_attribute(:weight)).to eq(5) # pre-existing data is not overwritten
        end
      end

      describe '#create' do
        it 'does not set issue weight' do
          perform :post, :create, issue: new_issue.attributes

          expect(response).to have_gitlab_http_status(302)
          expect(Issue.count).to eq(1)

          issue = Issue.first
          expect(issue.read_attribute(:weight)).to be_nil
        end
      end
    end
  end

  describe 'GET service_desk' do
    def get_service_desk(extra_params = {})
      get :service_desk, extra_params.merge(namespace_id: project.namespace, project_id: project)
    end

    context 'when Service Desk is available on the project' do
      let(:support_bot) { User.support_bot }
      let(:other_user) { create(:user) }
      let!(:service_desk_issue_1) { create(:issue, project: project, author: support_bot) }
      let!(:service_desk_issue_2) { create(:issue, project: project, author: support_bot, assignees: [other_user]) }
      let!(:other_user_issue) { create(:issue, project: project, author: other_user) }

      before do
        stub_licensed_features(service_desk: true)
      end

      it 'adds an author filter for the support bot user' do
        get_service_desk

        expect(assigns(:issues)).to contain_exactly(service_desk_issue_1, service_desk_issue_2)
      end

      it 'does not allow any other author to be set' do
        get_service_desk(author_username: other_user.username)

        expect(assigns(:issues)).to contain_exactly(service_desk_issue_1, service_desk_issue_2)
      end

      it 'supports other filters' do
        get_service_desk(assignee_username: other_user.username)

        expect(assigns(:issues)).to contain_exactly(service_desk_issue_2)
      end

      it 'allows an assignee to be specified by id' do
        get_service_desk(assignee_id: other_user.id)

        expect(assigns(:users)).to contain_exactly(other_user, support_bot)
      end
    end

    context 'when Service Desk is not available on the project' do
      before do
        stub_licensed_features(service_desk: false)
      end

      it 'returns a 404' do
        get_service_desk

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #discussions' do
    let(:issue)   { create(:issue, project: project) }
    let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

    context 'with a related system note' do
      let(:confidential_issue) { create(:issue, :confidential, project: project) }
      let!(:system_note) { SystemNoteService.relate_issue(issue, confidential_issue, user) }

      shared_examples 'user can see confidential issue' do |access_level|
        context "when a user is a #{access_level}" do
          before do
            project.add_user(user, access_level)
          end

          it 'displays related notes' do
            get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid

            discussions = json_response
            notes = discussions.flat_map {|d| d['notes']}

            expect(discussions.count).to equal(2)
            expect(notes).to include(a_hash_including('id' => system_note.id.to_s))
          end
        end
      end

      shared_examples 'user cannot see confidential issue' do |access_level|
        context "when a user is a #{access_level}" do
          before do
            project.add_user(user, access_level)
          end

          it 'redacts note related to a confidential issue' do
            get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid

            discussions = json_response
            notes = discussions.flat_map {|d| d['notes']}

            expect(discussions.count).to equal(1)
            expect(notes).not_to include(a_hash_including('id' => system_note.id.to_s))
          end
        end
      end

      context 'when authenticated' do
        before do
          sign_in(user)
        end

        %i(reporter developer maintainer).each do |access|
          it_behaves_like 'user can see confidential issue', access
        end

        it_behaves_like 'user cannot see confidential issue', :guest
      end

      context 'when unauthenticated' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'user cannot see confidential issue', Gitlab::Access::NO_ACCESS
      end
    end
  end
end
