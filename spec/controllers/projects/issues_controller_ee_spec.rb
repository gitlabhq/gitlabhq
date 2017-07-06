require('spec_helper')

describe Projects::IssuesController do
  let(:namespace) { create(:namespace) }
  let(:project)   { create(:project_empty_repo, namespace: namespace) }
  let(:user)      { create(:user) }
  let(:viewer)    { user }
  let(:issue)     { create(:issue, project: project) }

  describe 'POST export_csv' do
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
      let(:namespace) { create(:group, :private, plan: Namespace::BRONZE_PLAN) }

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
        it 'allows sorting by weight (ascending)' do
          expected = [issue, issue2].sort_by(&:weight)

          perform :get, :index, sort: 'weight_asc'

          expect(response).to have_http_status(200)
          expect(assigns(:issues)).to eq(expected)
        end

        it 'allows sorting by weight (descending)' do
          expected = [issue, issue2].sort { |a, b| b.weight <=> a.weight }

          perform :get, :index, sort: 'weight_desc'

          expect(response).to have_http_status(200)
          expect(assigns(:issues)).to eq(expected)
        end

        it 'allows filtering by weight' do
          _ = issue
          _ = issue2

          perform :get, :index, weight: 1
          
          expect(response).to have_http_status(200)
          expect(assigns(:issues)).to eq([issue2])
        end
      end

      describe '#update' do
        it 'sets issue weight' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6 }, format: :json

          expect(response).to have_http_status(200)
          expect(issue.reload.weight).to eq(6)
        end
      end

      describe '#create' do
        it 'sets issue weight' do
          perform :post, :create, issue: new_issue.attributes

          expect(response).to have_http_status(302)
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
        it 'ignores sorting by weight (ascending)'
        it 'ignores sorting by weight (descending)'

        it 'ignores filtering by weight' do
          expected = [issue, issue2]

          perform :get, :index, weight: 1

          expect(response).to have_http_status(200)
          expect(assigns(:issues)).to match_array(expected)
        end
      end

      describe '#update' do
        it 'does not set issue weight' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6 }, format: :json

          expect(response).to have_http_status(200)
          expect(issue.reload.weight).to be_nil
          expect(issue.reload.read_attribute(:weight)).to eq(5) # pre-existing data is not overwritten
        end
      end

      describe '#create' do
        it 'does not set issue weight' do
          perform :post, :create, issue: new_issue.attributes

          expect(response).to have_http_status(302)
          expect(Issue.count).to eq(1)

          issue = Issue.first
          expect(issue.read_attribute(:weight)).to be_nil
        end
      end
    end
  end
end
