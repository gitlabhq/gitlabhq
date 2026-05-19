# frozen_string_literal: true

require 'spec_helper'
require 'labkit/rspec/matchers'

RSpec.describe Projects::IssuesController, :request_store, feature_category: :team_planning do
  include ProjectForksHelper
  include_context 'includes Spam constants'

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user, reload: true) { create(:user) }

  let_it_be(:issue) { create(:issue, project: project) }
  let(:spam_action_response_fields) { { 'stub_spam_action_response_fields' => true } }

  before do
    # We need the spam_params object to be present in the request context
    Gitlab::RequestContext.start_request_context(request: request)
  end

  describe "GET #index" do
    context 'external issue tracker' do
      before_all do
        project.add_developer(user)
        create(:jira_integration, project: project)
      end

      before do
        sign_in(user)
      end

      context 'when GitLab issues disabled' do
        it 'returns 404 status' do
          project.issues_enabled = false
          project.save!

          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when GitLab issues enabled' do
        it 'redirects to work items index page' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to redirect_to(project_work_items_path(project))
        end
      end

      context 'when project has moved' do
        let_it_be(:new_project) { create(:project) }
        let_it_be(:issue) { create(:issue, project: new_project) }

        before_all do
          new_project.add_developer(user)
        end

        before do
          project.route.destroy!
          new_project.redirect_routes.create!(path: project.full_path)
        end

        it 'redirects to the new issue tracker from the old one' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to redirect_to(project_issues_path(new_project))
          expect(response).to have_gitlab_http_status(:moved_permanently)
        end

        it 'redirects from an old issue correctly' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: issue }

          expect(response).to redirect_to(project_issue_path(new_project, issue))
          expect(response).to have_gitlab_http_status(:moved_permanently)
        end
      end
    end

    context 'internal issue tracker' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      it 'redirects to work items index page' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to redirect_to(project_work_items_path(project))
      end

      it "returns 301 if request path doesn't match project path" do
        get :index, params: { namespace_id: project.namespace, project_id: project.path.upcase }

        expect(response).to redirect_to(project_issues_path(project))
      end

      it "returns 404 when issues are disabled" do
        project.issues_enabled = false
        project.save!

        get :index, params: { namespace_id: project.namespace, project_id: project }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'pagination' do
      let_it_be(:issue_list) { create_list(:issue, 2, project: project) }
      let(:collection) { project.issues }
      let(:last_page) { collection.page.total_pages }
      let(:params) do
        {
          namespace_id: project.namespace.to_param,
          project_id: project,
          state: 'opened'
        }
      end

      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'does not redirect when out of bounds on non-html requests' do
        get :index, params: params.merge(page: last_page + 1), format: 'atom'

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:issues).size).to eq(0)
      end
    end

    context 'external authorization' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in user
      end

      it_behaves_like 'unauthorized when external service denies access' do
        subject { get :index, params: { namespace_id: project.namespace, project_id: project } }
      end
    end
  end

  describe "GET #show" do
    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    it 'redirects to work item' do
      get :show, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

      expect(response).to redirect_to project_work_item_path(project, issue.iid)
    end

    context 'when issue is of type task' do
      let(:query) { {} }

      let_it_be(:task) { create(:issue, :task, project: project) }

      shared_examples 'redirects to show work item page' do
        it 'redirects to work item' do
          make_request

          expect(response).to redirect_to(project_work_item_path(project, task.iid, query))
        end
      end

      context 'show action' do
        let(:query) { { query: 'any' } }

        it_behaves_like 'redirects to show work item page' do
          subject(:make_request) do
            get :show, params: { namespace_id: project.namespace, project_id: project, id: task.iid, **query }
          end
        end
      end

      context 'edit action' do
        let(:query) { { query: 'any', edit: 'true' } }

        it_behaves_like 'redirects to show work item page' do
          subject(:make_request) do
            get :edit, params: { namespace_id: project.namespace, project_id: project, id: task.iid, query: 'any' }
          end
        end
      end

      context 'update action' do
        it_behaves_like 'redirects to show work item page' do
          subject(:make_request) do
            put :update, params: {
              namespace_id: project.namespace,
              project_id: project,
              id: task.iid,
              issue: { title: 'New title' }
            }
          end
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when visiting issues edit route and user can edit issue' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      it 'redirects to issues detail page with edit parameter' do
        get :edit, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(response).to redirect_to(project_work_item_path(project, issue, edit: 'true'))
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when visiting issues edit route and user cannot edit issue' do
      before_all do
        project.add_guest(user)
      end

      before do
        sign_in(user)
      end

      it 'redirects to issue detail page without edit parameter' do
        get :edit, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(response).to redirect_to(project_work_item_path(project, issue, params: {}))
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when item is a work item type and user cannot edit' do
      let_it_be(:work_item_issue) { create(:issue, :task, project: project) }

      before_all do
        project.add_guest(user)
      end

      before do
        sign_in(user)
      end

      it 'redirects to work item without edit parameter' do
        get :edit, params: { namespace_id: project.namespace, project_id: project, id: work_item_issue }

        expect(response).to redirect_to(project_work_item_path(project, work_item_issue.iid, params: {}))
        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe 'GET #new' do
    it 'redirects to signin if not logged in' do
      get :new, params: { namespace_id: project.namespace, project_id: project }

      expect(flash[:alert]).to eq I18n.t('devise.failure.unauthenticated')
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'on internal issue tracker' do
      before_all do
        project.add_guest(user)
      end

      before do
        sign_in user
      end

      it 'redirects to new work item' do
        get :new, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to redirect_to new_project_work_item_url(project)
      end
    end

    context 'on external issue tracker' do
      let_it_be(:service) do
        create(:custom_issue_tracker_integration, project: project, new_issue_url: 'http://test.com')
      end

      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)

        external = double
        allow(project).to receive(:external_issue_tracker).and_return(external)
      end

      context 'when GitLab issues disabled' do
        it 'returns 404 status' do
          project.issues_enabled = false
          project.save!

          get :new, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#related_branches' do
    subject { get :related_branches, params: params, format: :json }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    let(:developer) { user }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: issue.iid
      }
    end

    context 'the current user cannot read code' do
      it 'prevents access' do
        allow(controller).to receive(:can?).with(any_args).and_return(true)
        allow(controller).to receive(:can?).with(user, :read_code, project).and_return(false)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'there are no related branches' do
      it 'assigns empty arrays', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:related_branches)).to be_empty
        expect(response).to render_template('projects/issues/_related_branches')
        expect(json_response).to eq('html' => '')
      end
    end

    context 'there are related branches' do
      let(:missing_branch) { "#{issue.to_branch_name}-missing" }
      let(:unreadable_branch) { "#{issue.to_branch_name}-unreadable" }
      let(:pipeline) { build(:ci_pipeline, :success, project: project) }
      let(:master_branch) { 'master' }

      let(:related_branches) do
        [
          branch_info(issue.to_branch_name, pipeline.detailed_status(user)),
          branch_info(missing_branch, nil),
          branch_info(unreadable_branch, nil)
        ]
      end

      def branch_info(name, status)
        {
          name: name,
          link: controller.project_compare_path(project, from: master_branch, to: name),
          pipeline_status: status
        }
      end

      before do
        allow(controller).to receive(:find_routable!).and_return(project)
        allow(project).to receive(:default_branch).and_return(master_branch)
        allow_next_instance_of(Issues::RelatedBranchesService) do |service|
          allow(service).to receive(:execute).and_return(related_branches)
        end
      end

      it 'finds and assigns the appropriate branch information', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:related_branches)).to contain_exactly(
          branch_info(issue.to_branch_name, an_instance_of(Gitlab::Ci::Status::Success)),
          branch_info(missing_branch, be_nil),
          branch_info(unreadable_branch, be_nil)
        )
        expect(response).to render_template('projects/issues/_related_branches')
        expect(json_response).to match('html' => String)
      end
    end
  end

  # This spec runs as a request-style spec in order to invoke the
  # Rails router. A controller-style spec matches the wrong route, and
  # session['user_return_to'] becomes incorrect.
  describe 'Redirect after sign in', type: :request do
    before_all do
      project.add_developer(user)
    end

    before do
      login_as(user)
    end

    context 'with a JSON request' do
      it 'does not store the visited URL' do
        get project_issue_path(project, issue, format: :json)

        expect(session['user_return_to']).to be_blank
      end
    end

    context 'with an HTML request' do
      it 'stores the visited URL' do
        get project_issue_path(project, issue)

        expect(session['user_return_to']).to eq(project_issue_path(project, issue))
      end
    end
  end

  describe 'POST #move' do
    shared_examples 'move issue request' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      context 'when moving issue to another private project' do
        let_it_be(:another_project) { create(:project, :private) }

        context 'when user has access to move issue' do
          before_all do
            another_project.add_reporter(user)
          end

          it 'moves issue to another project' do
            move_issue

            expect(response).to have_gitlab_http_status :ok
            expect(another_project.issues).not_to be_empty
          end
        end

        context 'when user does not have access to move issue' do
          it 'responds with 404' do
            move_issue

            expect(response).to have_gitlab_http_status :not_found
          end
        end

        def move_issue
          post :move,
            params: {
              namespace_id: project.namespace.to_param,
              project_id: project,
              id: issue.iid,
              move_to_project_id: another_project.id
            },
            format: :json
        end
      end
    end

    it_behaves_like 'move issue request'
  end

  describe 'PUT #reorder' do
    let_it_be(:group)  { create(:group, projects: [project]) }
    let_it_be(:issue1) { create(:issue, project: project, relative_position: 10) }
    let_it_be(:issue2) { create(:issue, project: project, relative_position: 20) }
    let_it_be(:issue3) { create(:issue, project: project, relative_position: 30) }
    let_it_be(:other_group_project) { create(:project, group: create(:group)) }
    let_it_be(:other_group_issue) { create(:issue, project: other_group_project) }

    before do
      sign_in(user)
    end

    context 'when user has access' do
      before_all do
        project.add_developer(user)
      end

      context 'with valid params' do
        it 'reorders issues and returns a successful 200 response' do
          reorder_issue(issue1, move_after_id: issue2.id, move_before_id: issue3.id)

          [issue1, issue2, issue3].map(&:reload)

          expect(response).to have_gitlab_http_status(:ok)
          expect(issue1.relative_position)
            .to be_between(issue2.relative_position, issue3.relative_position)
        end
      end

      context 'with invalid params' do
        it 'returns a unprocessable entity 422 response for invalid move ids' do
          reorder_issue(issue1, move_after_id: 99, move_before_id: non_existing_record_id)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'returns a not found 404 response for invalid issue id' do
          reorder_issue(object_double(issue1, iid: non_existing_record_iid),
            move_after_id: issue2.id,
            move_before_id: issue3.id)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns a unprocessable entity 422 response for issues not in group' do
          reorder_issue(issue1, move_after_id: issue2.id, move_before_id: other_group_issue.id)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    context 'with unauthorized user' do
      before_all do
        project.add_guest(user)
      end

      it 'responds with 404' do
        reorder_issue(issue1, move_after_id: issue2.id, move_before_id: issue3.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def reorder_issue(issue, move_after_id: nil, move_before_id: nil)
      put :reorder, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: issue.iid,
        move_after_id: move_after_id,
        move_before_id: move_before_id
      }, format: :json
    end
  end

  describe 'PUT #update' do
    let(:issue_params) { { title: 'New title' } }

    subject do
      put :update, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: issue.to_param,
        issue: issue_params
      }, format: :json
    end

    before do
      sign_in(user)
    end

    context 'when user has access to update issue' do
      before_all do
        project.add_developer(user)
      end

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'updates the issue' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(issue.reload.title).to eq('New title')
      end

      context 'with issue_type param' do
        let(:issue_params) { { issue_type: 'incident' } }

        it 'permits the parameter' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(issue.reload.work_item_type.base_type).to eq('incident')
        end
      end

      context 'when an issue is identified as spam' do
        before do
          stub_application_setting(recaptcha_enabled: true)
          allow_next_instance_of(Spam::AkismetService) do |akismet_service|
            allow(akismet_service).to receive(:spam?).and_return(true)
          end
        end

        context 'when allow_possible_spam application setting is false' do
          before do
            expect(controller).to(receive(:spam_action_response_fields).with(issue)) do
              spam_action_response_fields
            end
          end

          it 'renders json with spam_action_response_fields' do
            subject

            expect(json_response).to eq(spam_action_response_fields)
          end
        end

        context 'when allow_possible_spam application setting is true' do
          before do
            stub_application_setting(allow_possible_spam: true)
          end

          it 'updates the issue' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(issue.reload.title).to eq('New title')
          end
        end
      end
    end

    context 'when user does not have access to update issue' do
      before_all do
        project.add_guest(user)
      end

      it 'responds with 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #realtime_changes' do
    before_all do
      project.add_developer(user)
    end

    def go(id:)
      get :realtime_changes,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id
        },
        format: :json
    end

    context 'when an issue was edited' do
      before do
        issue.update!(last_edited_by: user, last_edited_at: issue.created_at + 1.minute)

        sign_in(user)
      end

      it 'returns last edited time' do
        go(id: issue.iid)

        expect(json_response).to include('updated_at')
        expect(json_response['updated_at']).to eq(issue.last_edited_at.to_time.iso8601)
      end
    end

    context 'when an issue was edited by a deleted user' do
      let(:deleted_user) { create(:user) }

      before do
        issue.update!(last_edited_by: deleted_user, last_edited_at: Time.current)

        deleted_user.destroy!
        sign_in(user)
      end

      it 'returns 200' do
        go(id: issue.iid)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when getting the changes' do
      before do
        sign_in(user)
      end

      it 'returns the necessary data' do
        go(id: issue.iid)

        expect(json_response).to include('title_text', 'description', 'description_text')
        expect(json_response).to include('task_completion_status', 'lock_version')
      end
    end
  end

  describe 'Confidential Issues' do
    let_it_be(:project) { create(:project_empty_repo, :public) }
    let_it_be(:assignee) { create(:assignee) }
    let_it_be(:author) { create(:user) }
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:unescaped_parameter_value) { create(:issue, :confidential, project: project, author: author) }
    let_it_be(:request_forgery_timing_attack) { create(:issue, :confidential, project: project, assignees: [assignee]) }

    shared_examples_for 'restricted action' do |http_status|
      it 'returns 404 for guests' do
        sign_out(:user)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status :not_found
      end

      it 'returns 404 for non project members' do
        sign_in(non_member)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status :not_found
      end

      it 'returns 404 for project members with guest role' do
        sign_in(member)
        project.add_guest(member)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status :not_found
      end

      it "returns #{http_status[:success]} for author" do
        sign_in(author)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status http_status[:success]
      end

      it "returns #{http_status[:success]} for assignee" do
        sign_in(assignee)
        go(id: request_forgery_timing_attack.to_param)

        expect(response).to have_gitlab_http_status http_status[:success]
      end

      it "returns #{http_status[:success]} for project members" do
        sign_in(member)
        project.add_developer(member)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status http_status[:success]
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it "returns #{http_status[:success]} for admin" do
          sign_in(admin)
          go(id: unescaped_parameter_value.to_param)

          expect(response).to have_gitlab_http_status http_status[:success]
        end
      end

      context 'when admin mode is disabled' do
        xit 'returns 404 for admin' do
          sign_in(admin)
          go(id: unescaped_parameter_value.to_param)

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end

    describe 'PUT #update' do
      def update_issue(issue_params: {}, additional_params: {}, id: nil)
        id ||= issue.iid
        params = {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id,
          issue: { title: 'New title' }.merge(issue_params),
          format: :json
        }.merge(additional_params)

        put :update, params: params
      end

      def go(id:)
        update_issue(id: id)
      end

      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'restricted action', success: 200

      context 'changing the assignee' do
        let_it_be(:assignee) { create(:user) }

        before_all do
          project.add_developer(assignee)
        end

        it 'limits the attributes exposed on the assignee' do
          update_issue(issue_params: { assignee_ids: [assignee.id] })

          expect(json_response['assignees'].first.keys)
            .to include(*%w[id name username avatar_url state web_url])
        end
      end

      context 'Recaptcha is enabled' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          stub_application_setting(recaptcha_enabled: true)
        end

        context 'when SpamVerdictService allows the issue' do
          before do
            expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
              expect(verdict_service).to receive(:execute).and_return(ALLOW)
            end
          end

          it 'normally updates the issue' do
            expect { update_issue(issue_params: { title: 'Foo' }) }.to change { issue.reload.title }.to('Foo')
          end
        end

        context 'when an issue is identified as spam' do
          context 'when recaptcha is not verified' do
            before do
              allow_next_instance_of(Spam::AkismetService) do |akismet_service|
                allow(akismet_service).to receive(:spam?).and_return(true)
              end
            end

            context 'when allow_possible_spam application setting is false' do
              it 'rejects an issue recognized as spam' do
                expect { update_issue }.not_to change { issue.reload.title }
              end

              it 'rejects an issue recognized as a spam when reCAPTCHA disabled' do
                stub_application_setting(recaptcha_enabled: false)

                expect { update_issue }.not_to change { issue.reload.title }
              end

              it 'creates a spam log' do
                expect { update_issue(issue_params: { title: 'Spam title' }) }
                  .to log_spam(title: 'Spam title', noteable_type: 'Issue')
              end

              context 'renders properly' do
                render_views

                before do
                  expect(controller).to(receive(:spam_action_response_fields).with(issue)) do
                    spam_action_response_fields
                  end
                end

                it 'renders spam_action_response_fields json response' do
                  update_issue

                  expect(response).to have_gitlab_http_status(:conflict)
                  expect(json_response).to eq(spam_action_response_fields)
                end
              end
            end

            context 'when allow_possible_spam application setting is true' do
              before do
                stub_application_setting(allow_possible_spam: true)
              end

              it 'updates the issue recognized as spam' do
                expect { update_issue }.to change { issue.reload.title }
              end

              it 'creates a spam log' do
                expect { update_issue(issue_params: { title: 'Spam title' }) }
                  .to log_spam(
                    title: 'Spam title', description: issue.description,
                    noteable_type: 'Issue', recaptcha_verified: false
                  )
              end

              it 'returns 200 status' do
                update_issue

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end

          context 'when recaptcha is verified' do
            let_it_be(:spammy_title) { 'Whatever' }
            let_it_be(:spam_logs) { create_list(:spam_log, 2, user: user, title: spammy_title) }

            def update_verified_issue
              update_issue(issue_params: { title: spammy_title }, additional_params: { spam_log_id: spam_logs.last.id, 'g-recaptcha-response': 'a-valid-captcha-response' })
            end

            it 'returns 200 status' do
              update_verified_issue
              expect(response).to have_gitlab_http_status(:ok)
            end

            it 'accepts an issue after reCAPTCHA is verified' do
              expect { update_verified_issue }.to change { issue.reload.title }.to(spammy_title)
            end

            it 'marks spam log as recaptcha_verified' do
              expect { update_verified_issue }.to change { SpamLog.last.recaptcha_verified }.from(false).to(true)
            end

            it 'does not mark spam log as recaptcha_verified when it does not belong to current_user' do
              create(:spam_log)

              expect { update_verified_issue }
                .not_to change { SpamLog.last.recaptcha_verified }
            end
          end
        end
      end
    end

    describe 'GET #show' do
      it_behaves_like 'restricted action', success: 302

      def go(id:)
        get :show,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: id
          }
      end

      it 'redirects to consolidated list' do
        sign_in(user)
        go(id: issue.to_param)

        expect(response).to redirect_to(project_work_item_path(project, issue.iid))
      end
    end

    describe 'GET #realtime_changes' do
      it_behaves_like 'restricted action', success: 302

      def go(id:)
        get :realtime_changes,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: id
          }
      end
    end

    describe 'GET #edit' do
      it_behaves_like 'restricted action', success: 302

      def go(id:)
        get :edit,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: id
          }
      end
    end

    describe 'PUT #update' do
      it_behaves_like 'restricted action', success: 302

      def go(id:)
        put :update,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: id,
            issue: { title: 'New title' }
          }
      end
    end
  end

  describe 'POST #create' do
    let(:project) { create(:project, :public, developers: user) }

    def post_new_issue(issue_attrs = {}, additional_params = {})
      sign_in(user)

      post :create, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        issue: { title: 'Title', description: 'Description' }.merge(issue_attrs)
      }.merge(additional_params)

      project.issues.first
    end

    context 'when creating an incident' do
      it 'sets the correct issue_type' do
        issue = post_new_issue(issue_type: 'incident')

        expect(issue.work_item_type.base_type).to eq('incident')
      end
    end

    context 'when trying to create a task' do
      it 'sets the correct issue_type' do
        issue = post_new_issue(issue_type: 'task')

        expect(issue.work_item_type.base_type).to eq('task')
      end
    end

    context 'when trying to create a objective' do
      it 'defaults to issue type' do
        issue = post_new_issue(issue_type: 'objective')

        expect(issue.work_item_type.base_type).to eq('issue')
      end
    end

    context 'when trying to create a key_result' do
      it 'defaults to issue type' do
        issue = post_new_issue(issue_type: 'key_result')

        expect(issue.work_item_type.base_type).to eq('issue')
      end
    end

    context 'when trying to create an epic' do
      it 'defaults to issue type' do
        issue = post_new_issue(issue_type: 'epic')

        expect(issue.work_item_type.base_type).to eq('issue')
      end
    end

    context 'when create service return an unrecoverable error with http_status' do
      let(:http_status) { 403 }

      before do
        allow_next_instance_of(::Issues::CreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'unrecoverable error', http_status: http_status)
          )
        end
      end

      it 'renders 403 and logs the error' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'Cannot create issue',
          errors: ['unrecoverable error'],
          http_status: http_status
        )

        post_new_issue

        expect(response).to have_gitlab_http_status :forbidden
      end

      context 'when no render method is found for the returned http_status' do
        let(:http_status) { nil }

        it 'renders 404 and logs the error' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: 'Cannot create issue',
            errors: ['unrecoverable error'],
            http_status: http_status
          )

          post_new_issue

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end

    it 'creates the issue successfully', :aggregate_failures do
      issue = post_new_issue

      expect(issue).to be_a(Issue)
      expect(issue.persisted?).to eq(true)
      expect(issue.work_item_type.base_type).to eq('issue')
    end

    context 'resolving discussions in MergeRequest' do
      let_it_be(:discussion) { create(:diff_note_on_merge_request).to_discussion }
      let_it_be(:merge_request) { discussion.noteable }
      let_it_be(:project) { merge_request.source_project }

      let(:merge_request_params) do
        { merge_request_to_resolve_discussions_of: merge_request.iid }
      end

      before_all do
        project.add_maintainer(user)
      end

      before do
        sign_in user
      end

      def post_issue(other_params: {}, **issue_params)
        post :create, params: { namespace_id: project.namespace.to_param, project_id: project, issue: issue_params, merge_request_to_resolve_discussions_of: merge_request.iid }.merge(other_params)
      end

      it 'creates an issue for the project' do
        expect { post_issue(title: 'Hello') }.to change { project.issues.count }.by(1)
      end

      it "doesn't overwrite given params" do
        post_issue(description: 'Manually entered description')

        expect(assigns(:issue).description).to eq('Manually entered description')
      end

      it 'resolves the discussion in the merge_request' do
        post_issue(title: 'Hello')
        discussion.first_note.reload

        expect(discussion.resolved?).to eq(true)
      end

      it 'sets a flash message' do
        post_issue(title: 'Hello')

        expect(flash[:notice]).to eq(_('Resolved all discussions.'))
      end

      describe "resolving a single discussion" do
        before do
          post_issue(title: 'Hello', other_params: { discussion_to_resolve: discussion.id })
        end

        it 'resolves a single discussion' do
          discussion.first_note.reload

          expect(discussion.resolved?).to eq(true)
        end

        it 'sets a flash message that one discussion was resolved' do
          expect(flash[:notice]).to eq(_('Resolved 1 discussion.'))
        end
      end
    end

    context 'Recaptcha is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'when SpamVerdictService allows the issue' do
        before do
          expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
            expect(verdict_service).to receive(:execute).and_return(ALLOW)
          end
        end

        it 'creates an issue' do
          expect { post_new_issue(title: 'Some title') }.to change { Issue.count }
        end
      end

      context 'when an issue is identified as spam and requires recaptcha' do
        context 'when captcha is not verified' do
          before do
            allow_next_instance_of(Spam::AkismetService) do |akismet_service|
              allow(akismet_service).to receive(:spam?).and_return(true)
            end
          end

          def post_spam_issue
            post_new_issue(title: 'Spam Title', description: 'Spam lives here')
          end

          context 'when allow_possible_spam application setting is false' do
            it 'rejects an issue recognized as spam' do
              expect { post_spam_issue }.not_to change { Issue.count }
            end

            it 'creates a spam log' do
              expect { post_spam_issue }
                .to log_spam(title: 'Spam Title', noteable_type: 'Issue', recaptcha_verified: false)
            end

            it 'does not create an issue when it is not valid' do
              expect { post_new_issue(title: '') }.not_to change { Issue.count }
            end

            it 'does not create an issue when reCAPTCHA is not enabled' do
              stub_application_setting(recaptcha_enabled: false)

              expect { post_spam_issue }.not_to change { Issue.count }
            end
          end

          context 'when allow_possible_spam application setting is true' do
            before do
              stub_application_setting(allow_possible_spam: true)
            end

            it 'creates an issue recognized as spam' do
              expect { post_spam_issue }.to change { Issue.count }
            end

            it 'creates a spam log' do
              expect { post_spam_issue }
                .to log_spam(title: 'Spam Title', noteable_type: 'Issue', recaptcha_verified: false)
            end

            it 'does not create an issue when it is not valid' do
              expect { post_new_issue(title: '') }.not_to change { Issue.count }
            end
          end
        end

        context 'when Recaptcha is verified' do
          let_it_be(:spam_logs) { create_list(:spam_log, 2, user: user, title: 'Title') }
          let_it_be_with_reload(:last_spam_log) { spam_logs.last }
          let_it_be(:other_user_spam_log) { create(:spam_log) }

          def post_verified_issue
            post_new_issue({}, { spam_log_id: last_spam_log.id, 'g-recaptcha-response': 'abc123' })
          end

          before do
            expect_next_instance_of(Captcha::CaptchaVerificationService) do |instance|
              expect(instance).to receive(:execute).and_return(true)
            end
          end

          it 'accepts an issue after reCAPTCHA is verified' do
            expect { post_verified_issue }.to change { Issue.count }
          end

          it 'marks spam log as recaptcha_verified' do
            expect { post_verified_issue }.to change { last_spam_log.reload.recaptcha_verified }.from(false).to(true)
          end

          it 'does not mark spam log as recaptcha_verified when it does not belong to current_user' do
            expect { post_new_issue({}, { spam_log_id: other_user_spam_log.id, 'g-recaptcha-response': true }) }
              .not_to change { last_spam_log.recaptcha_verified }
          end
        end
      end
    end

    context 'user agent details are saved' do
      before do
        request.env['action_dispatch.remote_ip'] = '127.0.0.1'
        Gitlab::RequestContext.start_request_context(request: request)
      end

      it 'creates a user agent detail' do
        expect { post_new_issue }.to change { UserAgentDetail.count }.by(1)
      end
    end

    context 'when description has quick actions' do
      before do
        sign_in(user)
      end

      it 'can add spent time' do
        issue = post_new_issue(description: '/spend 1h')

        expect(issue.total_time_spent).to eq(3600)
      end

      it 'can set the time estimate' do
        issue = post_new_issue(description: '/estimate 2h')

        expect(issue.time_estimate).to eq(7200)
      end
    end

    context 'when created from sentry error' do
      subject { post_new_issue(sentry_issue_attributes: { sentry_issue_identifier: 1234567 }) }

      it 'creates an issue' do
        expect { subject }.to change { Issue.count }
      end

      it 'creates a sentry issue' do
        expect { subject }.to change { SentryIssue.count }
      end
    end

    context 'when the endpoint receives requests above the limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        stub_application_setting(issues_create_limit: 1)
      end

      context 'when issue creation limits imposed' do
        before do
          sign_in(user)
        end

        it 'prevents from creating more issues', :request_store do
          2.times { post_new_issue_in_project }

          expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
          expect(response).to have_gitlab_http_status(:too_many_requests)
        end

        it 'logs the event on auth.log' do
          attributes = {
            message: 'Application_Rate_Limiter_Request',
            env: :issues_create_request_limit,
            remote_ip: '0.0.0.0',
            method: 'POST',
            path: "/#{project.full_path}/-/issues",
            user_id: user.id,
            username: user.username
          }

          expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

          2.times { post_new_issue_in_project }
        end

        def post_new_issue_in_project
          post :create, params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            issue: { title: 'Title', description: 'Description' }
          }
        end
      end
    end

    context 'setting issue type' do
      let(:issue_type) { 'issue' }

      subject { post_new_issue(issue_type: issue_type)&.work_item_type&.base_type }

      it { is_expected.to eq('issue') }

      context 'incident issue' do
        let(:issue_type) { 'incident' }

        it { is_expected.to eq(issue_type) }
      end
    end
  end

  describe "DELETE #destroy" do
    let_it_be(:owner) { create(:user) }

    before_all do
      project.add_owner(owner)
    end

    before do
      sign_in(owner)
    end

    it 'redirects to work item' do
      delete :destroy, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: issue.iid,
        destroy_confirm: true
      }

      expect(response).to redirect_to project_work_item_path(project, issue.iid)
    end

    context "when the user is a developer" do
      before do
        sign_in(user)
      end

      it "does not delete the issue, returning :not_found" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when the user is owner" do
      before do
        sign_in(owner)
      end

      it "deletes the issue" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, destroy_confirm: true, format: :json }

        expect(response).to have_gitlab_http_status(:ok)
        expect(controller).to set_flash[:notice].to(/The issue was successfully deleted\./)
      end

      it "prevents deletion if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(response).to have_gitlab_http_status(:found)
        expect(controller).to set_flash[:notice].to('Destroy confirmation not provided for issue')
      end

      it "prevents deletion in JSON format if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, format: 'json' }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'errors' => 'Destroy confirmation not provided for issue' })
      end
    end
  end

  describe 'POST #toggle_award_emoji' do
    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    subject(:make_request) do
      post(:toggle_award_emoji, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: issue.iid,
        name: emoji_name
      })
    end

    let(:emoji_name) { AwardEmoji::THUMBS_UP }

    it 'redirects to work item' do
      make_request

      expect(response).to redirect_to project_work_item_path(project, issue.iid)
    end
  end

  describe 'POST create_merge_request' do
    let(:target_project_id) { nil }

    let_it_be_with_reload(:project) { create(:project, :repository, :public) }
    let(:issue) { create(:issue, project: project) }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    it 'creates a new merge request' do
      expect { create_merge_request }.to change { project.merge_requests.count }.by(1)
    end

    it 'render merge request as json' do
      create_merge_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('merge_request')
    end

    it 'is not available when the project is archived' do
      project.update!(archived: true)

      create_merge_request

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'is not available for users who cannot create merge requests' do
      sign_in(create(:user))

      create_merge_request

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'invalid branch name' do
      it 'is unprocessable' do
        post(
          :create_merge_request,
          params: {
            target_project_id: nil,
            branch_name: 'master',
            ref: 'master',
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: issue.to_param
          },
          format: :json
        )

        expect(response.body).to eq('Branch already exists')
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'target_project_id is set' do
      let(:target_project) { fork_project(project, user, repository: true) }
      let(:target_project_id) { target_project.id }

      it 'creates a new merge request', :sidekiq_might_not_need_inline do
        expect { create_merge_request }.to change { target_project.merge_requests.count }.by(1)
      end
    end

    it 'starts covered experience for create_merge_request' do
      expect { create_merge_request }.to start_user_experience(:create_merge_request)
    end

    def create_merge_request
      post(
        :create_merge_request,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: issue.to_param,
          target_project_id: target_project_id
        },
        format: :json
      )
    end
  end

  describe 'POST #import_csv' do
    let_it_be(:project) { create(:project, :public) }

    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

    context 'unauthorized' do
      it 'returns 404 for guests' do
        sign_out(:user)

        import_csv

        expect(response).to have_gitlab_http_status :not_found
      end

      context 'when user is a reporter' do
        before_all do
          project.add_reporter(user)
        end

        before do
          sign_in(user)
        end

        it 'returns 404 for project members with reporter role' do
          import_csv

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end

    context 'authorized' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      context 'when upload proceeds correctly' do
        it "returns 302 for project members with developer role" do
          import_csv

          expect(flash[:notice]).to eq(_("Your issues are being imported. Once finished, you'll get a confirmation email."))
          expect(response).to redirect_to(project_issues_path(project))
        end

        it 'enqueues an import job' do
          expect(ImportIssuesCsvWorker).to receive(:perform_async).with(user.id, project.id, Integer)

          import_csv
        end
      end

      context 'when upload fails' do
        it "shows error when upload fails" do
          expect_next_instance_of(UploadService) do |upload_service|
            expect(upload_service).to receive(:execute).and_return(nil)
          end

          import_csv

          expect(flash[:alert]).to include(_('File upload error.'))
          expect(response).to redirect_to(project_issues_path(project))
        end
      end
    end

    def import_csv
      post :import_csv, params: { namespace_id: project.namespace.to_param,
                                  project_id: project.to_param,
                                  file: file }
    end
  end

  describe 'POST export_csv' do
    let(:viewer) { user }

    before_all do
      project.add_developer(user)
    end

    def request_csv
      post :export_csv, params: { namespace_id: project.namespace.to_param, project_id: project.to_param }
    end

    context 'when logged in' do
      before do
        sign_in(viewer)
      end

      it 'allows CSV export' do
        expect(IssuableExportCsvWorker).to receive(:perform_async)
          .with(:issue, viewer.id, project.id, hash_including(
            'issue_types' => Issue::TYPES_FOR_LIST,
            'include_subepics' => true
          ))

        request_csv

        expect(response).to redirect_to(project_issues_path(project))
        expect(controller).to set_flash[:notice].to match(/\AYour CSV export has started/i)
      end
    end

    context 'when not logged in' do
      it 'redirects to the sign in page' do
        request_csv

        expect(IssuableExportCsvWorker).not_to receive(:perform_async)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET service_desk' do
    let_it_be(:project) { create(:project_empty_repo, :public) }
    let_it_be(:support_bot) { create(:support_bot) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:service_desk_issue_1) { create(:issue, project: project, author: support_bot) }
    let_it_be(:service_desk_issue_2) { create(:issue, project: project, author: support_bot, assignees: [other_user]) }
    let_it_be(:other_user_issue) { create(:issue, project: project, author: other_user) }

    def get_service_desk(extra_params = {})
      get :service_desk, params: extra_params.merge(namespace_id: project.namespace, project_id: project)
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

      expect(assigns(:issues)).to contain_exactly(service_desk_issue_2)
    end
  end

  describe 'GET #discussions' do
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

    context 'when authenticated' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
      end

      context do
        it_behaves_like 'discussions provider' do
          let_it_be(:note_on_issue1) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: create(:user)) }
          let_it_be(:note_on_issue2) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: create(:user)) }

          let(:requested_iid) { issue.iid }
          let(:expected_discussion_count) { 3 }
          let(:expected_discussion_ids) do
            [
              issue.notes.first.discussion_id,
              note_on_issue1.discussion_id,
              note_on_issue2.discussion_id
            ]
          end
        end
      end

      it 'returns discussion json' do
        get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(json_response.first.keys).to match_array(%w[id reply_id expanded notes diff_discussion discussion_path individual_note resolvable commit_id for_commit project_id confidential resolve_path resolved resolved_at resolved_by resolved_by_push])
      end

      it 'starts and completes covered experience for load_comments' do
        expect do
          get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
        end.to start_user_experience(:load_comments)
        .and complete_user_experience(:load_comments)
      end

      it 'renders the author status html if there is a status' do
        create(:user_status, user: discussion.author)

        get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        note_json = json_response.first['notes'].first

        expect(note_json['author']['status_tooltip_html']).to be_present
      end

      it 'does not cause an extra query for the status' do
        control = ActiveRecord::QueryRecorder.new do
          get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
        end

        create(:user_status, user: discussion.author)
        second_discussion = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: create(:user))
        create(:user_status, user: second_discussion.author)

        expect { get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid } }
          .not_to exceed_query_limit(control).with_threshold(9)
      end

      context 'when user is setting notes filters' do
        let_it_be(:issuable) { issue }
        let_it_be(:issuable_parent) { project }
        let_it_be(:discussion_note) { create(:discussion_note_on_issue, :system, noteable: issuable, project: project) }

        it_behaves_like 'issuable notes filter'
      end

      context 'with cross-reference system note', :request_store do
        let_it_be(:new_issue) { create(:issue) }

        let(:cross_reference) { "mentioned in #{new_issue.to_reference(issue.project)}" }

        before do
          create(:discussion_note_on_issue, :system, noteable: issue, project: issue.project, note: cross_reference)
        end

        it 'filters notes that the user should not see' do
          get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

          expect(json_response.count).to eq(1)
        end

        it 'does not result in N+1 queries' do
          # Instantiate the controller variables to ensure QueryRecorder has an accurate base count
          get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

          RequestStore.clear!

          control = ActiveRecord::QueryRecorder.new do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
          end

          RequestStore.clear!

          create_list(:discussion_note_on_issue, 2, :system, noteable: issue, project: issue.project, note: cross_reference)

          expect do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
          end.not_to exceed_query_limit(control)
        end

        context 'when reference is invalid' do
          let(:cross_reference) { "mentioned in some/invalid/project#123" }

          it 'does not include the system note' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            expect(json_response.count).to eq(1)
          end
        end
      end

      context 'private project' do
        let_it_be(:branch_note) { create(:discussion_note_on_issue, :system, noteable: issue, project: project) }
        let_it_be(:commit_note) { create(:discussion_note_on_issue, :system, noteable: issue, project: project) }
        let_it_be(:branch_note_meta) { create(:system_note_metadata, note: branch_note, action: "branch") }
        let_it_be(:commit_note_meta) { create(:system_note_metadata, note: commit_note, action: "commit") }

        context 'user is allowed access' do
          before_all do
            project.add_member(user, :maintainer)
          end

          it 'displays all available notes' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            expect(json_response.length).to eq(3)
          end
        end

        context 'user is a guest' do
          let(:json_response_note_ids) do
            json_response
              .flat_map { |discussion| discussion["notes"] }
              .map { |note| note["id"].to_i }
          end

          before_all do
            project.add_guest(user)
          end

          it 'does not display notes w/type listed in TYPES_RESTRICTED_BY_ACCESS_LEVEL' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            expect(json_response.length).to eq(2)
            expect(json_response_note_ids).not_to include(branch_note.id)
          end
        end
      end
    end
  end

  describe 'GET #designs' do
    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    it 'redirects to work item path' do
      get :designs, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

      expect(response).to redirect_to(project_work_item_path(project, issue.iid, params: {}))
    end

    context 'when project has moved' do
      let(:new_project) { create(:project) }
      let(:issue) { create(:issue, project: new_project) }

      before do
        sign_in(user)

        project.route.destroy!
        new_project.redirect_routes.create!(path: project.full_path)
        new_project.add_developer(user)
      end

      it 'redirects from an old issue/designs correctly' do
        get :designs, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: issue
        }

        expect(response).to redirect_to(designs_project_issue_path(new_project, issue))
        expect(response).to have_gitlab_http_status(:moved_permanently)
      end
    end
  end
end
