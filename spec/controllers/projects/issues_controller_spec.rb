# frozen_string_literal: true

require 'spec_helper'

describe Projects::IssuesController do
  include ProjectForksHelper

  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:issue)   { create(:issue, project: project) }

  describe "GET #index" do
    context 'external issue tracker' do
      before do
        sign_in(user)
        project.add_developer(user)
        create(:jira_service, project: project)
      end

      context 'when GitLab issues disabled' do
        it 'returns 404 status' do
          project.issues_enabled = false
          project.save!

          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when GitLab issues enabled' do
        it 'renders the "index" template' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:index)
        end
      end

      context 'when project has moved' do
        let(:new_project) { create(:project) }
        let(:issue) { create(:issue, project: new_project) }

        before do
          project.route.destroy
          new_project.redirect_routes.create!(path: project.full_path)
          new_project.add_developer(user)
        end

        it 'redirects to the new issue tracker from the old one' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to redirect_to(project_issues_path(new_project))
          expect(response).to have_gitlab_http_status(302)
        end

        it 'redirects from an old issue correctly' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: issue }

          expect(response).to redirect_to(project_issue_path(new_project, issue))
          expect(response).to have_gitlab_http_status(302)
        end
      end
    end

    context 'internal issue tracker' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it_behaves_like "issuables list meta-data", :issue

      it_behaves_like 'set sort order from user preference' do
        let(:sorting_param) { 'updated_asc' }
      end

      it "returns index" do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(200)
      end

      it "returns 301 if request path doesn't match project path" do
        get :index, params: { namespace_id: project.namespace, project_id: project.path.upcase }

        expect(response).to redirect_to(project_issues_path(project))
      end

      it "returns 404 when issues are disabled" do
        project.issues_enabled = false
        project.save!

        get :index, params: { namespace_id: project.namespace, project_id: project }
        expect(response).to have_gitlab_http_status(404)
      end
    end

    it_behaves_like 'paginated collection' do
      let!(:issue_list) { create_list(:issue, 2, project: project) }
      let(:collection) { project.issues }
      let(:params) do
        {
          namespace_id: project.namespace.to_param,
          project_id: project,
          state: 'opened'
        }
      end

      before do
        sign_in(user)
        project.add_developer(user)
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'does not use pagination if disabled' do
        allow(controller).to receive(:pagination_disabled?).and_return(true)

        get :index, params: params.merge(page: last_page + 1)

        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:issues).size).to eq(2)
      end
    end

    context 'with relative_position sorting' do
      let!(:issue_list) { create_list(:issue, 2, project: project) }

      before do
        sign_in(user)
        project.add_developer(user)
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'overrides the number allowed on the page' do
        get :index,
          params: {
            namespace_id: project.namespace.to_param,
            project_id:   project,
            sort:         'relative_position'
          }

        expect(assigns(:issues).count).to eq 2
      end

      it 'allows the default number on the page' do
        get :index,
          params: {
            namespace_id: project.namespace.to_param,
            project_id:   project
          }

        expect(assigns(:issues).count).to eq 1
      end
    end

    context 'external authorization' do
      before do
        sign_in user
        project.add_developer(user)
      end

      it_behaves_like 'unauthorized when external service denies access' do
        subject { get :index, params: { namespace_id: project.namespace, project_id: project } }
      end
    end
  end

  describe 'GET #new' do
    it 'redirects to signin if not logged in' do
      get :new, params: { namespace_id: project.namespace, project_id: project }

      expect(flash[:alert]).to eq I18n.t('devise.failure.unauthenticated')
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'internal issue tracker' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it 'builds a new issue' do
        get :new, params: { namespace_id: project.namespace, project_id: project }

        expect(assigns(:issue)).to be_a_new(Issue)
      end

      it 'fills in an issue for a merge request' do
        project_with_repository = create(:project, :repository)
        project_with_repository.add_developer(user)
        mr = create(:merge_request_with_diff_notes, source_project: project_with_repository)

        get :new, params: { namespace_id: project_with_repository.namespace, project_id: project_with_repository, merge_request_to_resolve_discussions_of: mr.iid }

        expect(assigns(:issue).title).not_to be_empty
        expect(assigns(:issue).description).not_to be_empty
      end

      it 'fills in an issue for a discussion' do
        note = create(:note_on_merge_request, project: project)

        get :new, params: { namespace_id: project.namespace.path, project_id: project, merge_request_to_resolve_discussions_of: note.noteable.iid, discussion_to_resolve: note.discussion_id }

        expect(assigns(:issue).title).not_to be_empty
        expect(assigns(:issue).description).not_to be_empty
      end
    end

    context 'external issue tracker' do
      let!(:service) do
        create(:custom_issue_tracker_service, project: project, title: 'Custom Issue Tracker', new_issue_url: 'http://test.com')
      end

      before do
        sign_in(user)
        project.add_developer(user)

        external = double
        allow(project).to receive(:external_issue_tracker).and_return(external)
      end

      context 'when GitLab issues disabled' do
        it 'returns 404 status' do
          project.issues_enabled = false
          project.save!

          get :new, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when GitLab issues enabled' do
        it 'renders the "new" template' do
          get :new, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  # This spec runs as a request-style spec in order to invoke the
  # Rails router. A controller-style spec matches the wrong route, and
  # session['user_return_to'] becomes incorrect.
  describe 'Redirect after sign in', type: :request do
    context 'with an AJAX request' do
      it 'does not store the visited URL' do
        get project_issue_path(project, issue), xhr: true

        expect(session['user_return_to']).to be_blank
      end
    end

    context 'without an AJAX request' do
      it 'stores the visited URL' do
        get project_issue_path(project, issue)

        expect(session['user_return_to']).to eq(project_issue_path(project, issue))
      end
    end
  end

  describe 'POST #move' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    context 'when moving issue to another private project' do
      let(:another_project) { create(:project, :private) }

      context 'when user has access to move issue' do
        before do
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

  describe 'PUT #reorder' do
    let(:group)   { create(:group, projects: [project]) }
    let!(:issue1) { create(:issue, project: project, relative_position: 10) }
    let!(:issue2) { create(:issue, project: project, relative_position: 20) }
    let!(:issue3) { create(:issue, project: project, relative_position: 30) }

    before do
      sign_in(user)
    end

    context 'when user has access' do
      before do
        project.add_developer(user)
      end

      context 'with valid params' do
        it 'reorders issues and returns a successful 200 response' do
          reorder_issue(issue1,
            move_after_id: issue2.id,
            move_before_id: issue3.id,
            group_full_path: group.full_path)

          [issue1, issue2, issue3].map(&:reload)

          expect(response).to have_gitlab_http_status(200)
          expect(issue1.relative_position)
            .to be_between(issue2.relative_position, issue3.relative_position)
        end
      end

      context 'with invalid params' do
        it 'returns a unprocessable entity 422 response for invalid move ids' do
          reorder_issue(issue1, move_after_id: 99, move_before_id: 999)

          expect(response).to have_gitlab_http_status(422)
        end

        it 'returns a not found 404 response for invalid issue id' do
          reorder_issue(object_double(issue1, iid: 999),
            move_after_id: issue2.id,
            move_before_id: issue3.id)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns a unprocessable entity 422 response for issues not in group' do
          another_group = create(:group)

          reorder_issue(issue1,
            move_after_id: issue2.id,
            move_before_id: issue3.id,
            group_full_path: another_group.full_path)

          expect(response).to have_gitlab_http_status(422)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        project.add_guest(user)
      end

      it 'responds with 404' do
        reorder_issue(issue1, move_after_id: issue2.id, move_before_id: issue3.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def reorder_issue(issue, move_after_id: nil, move_before_id: nil, group_full_path: nil)
      put :reorder,
           params: {
               namespace_id: project.namespace.to_param,
               project_id: project,
               id: issue.iid,
               move_after_id: move_after_id,
               move_before_id: move_before_id,
               group_full_path: group_full_path
           },
           format: :json
    end
  end

  describe 'PUT #update' do
    subject do
      put :update,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: issue.to_param,
          issue: { title: 'New title' }
        },
        format: :json
    end

    before do
      sign_in(user)
    end

    context 'when user has access to update issue' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.add_developer(user)
      end

      it 'updates the issue' do
        subject

        expect(response).to have_http_status(:ok)
        expect(issue.reload.title).to eq('New title')
      end

      context 'when Akismet is enabled and the issue is identified as spam' do
        before do
          stub_application_setting(recaptcha_enabled: true)
          expect_next_instance_of(AkismetService) do |akismet_service|
            expect(akismet_service).to receive_messages(spam?: true)
          end
        end

        context 'when allow_possible_spam feature flag is false' do
          before do
            stub_feature_flags(allow_possible_spam: false)
          end

          it 'renders json with recaptcha_html' do
            subject

            expect(json_response).to have_key('recaptcha_html')
          end
        end

        context 'when allow_possible_spam feature flag is true' do
          it 'updates the issue' do
            subject

            expect(response).to have_http_status(:ok)
            expect(issue.reload.title).to eq('New title')
          end
        end
      end
    end

    context 'when user does not have access to update issue' do
      before do
        project.add_guest(user)
      end

      it 'responds with 404' do
        subject

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #realtime_changes' do
    def go(id:)
      get :realtime_changes,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id
        }
    end

    context 'when an issue was edited' do
      before do
        project.add_developer(user)

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
        project.add_developer(user)

        issue.update!(last_edited_by: deleted_user, last_edited_at: Time.now)

        deleted_user.destroy
        sign_in(user)
      end

      it 'returns 200' do
        go(id: issue.iid)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when getting the changes' do
      before do
        project.add_developer(user)

        sign_in(user)
      end

      it 'returns the necessary data' do
        go(id: issue.iid)

        expect(json_response).to include('title_text', 'description', 'description_text')
        expect(json_response).to include('task_status', 'lock_version')
      end
    end
  end

  describe 'Confidential Issues' do
    let(:project) { create(:project_empty_repo, :public) }
    let(:assignee) { create(:assignee) }
    let(:author) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let!(:issue) { create(:issue, project: project) }
    let!(:unescaped_parameter_value) { create(:issue, :confidential, project: project, author: author) }
    let!(:request_forgery_timing_attack) { create(:issue, :confidential, project: project, assignees: [assignee]) }

    describe 'GET #index' do
      it 'does not list confidential issues for guests' do
        sign_out(:user)
        get_issues

        expect(assigns(:issues)).to eq [issue]
      end

      it 'does not list confidential issues for non project members' do
        sign_in(non_member)
        get_issues

        expect(assigns(:issues)).to eq [issue]
      end

      it 'does not list confidential issues for project members with guest role' do
        sign_in(member)
        project.add_guest(member)

        get_issues

        expect(assigns(:issues)).to eq [issue]
      end

      it 'lists confidential issues for author' do
        sign_in(author)
        get_issues

        expect(assigns(:issues)).to include unescaped_parameter_value
        expect(assigns(:issues)).not_to include request_forgery_timing_attack
      end

      it 'lists confidential issues for assignee' do
        sign_in(assignee)
        get_issues

        expect(assigns(:issues)).not_to include unescaped_parameter_value
        expect(assigns(:issues)).to include request_forgery_timing_attack
      end

      it 'lists confidential issues for project members' do
        sign_in(member)
        project.add_developer(member)

        get_issues

        expect(assigns(:issues)).to include unescaped_parameter_value
        expect(assigns(:issues)).to include request_forgery_timing_attack
      end

      it 'lists confidential issues for admin' do
        sign_in(admin)
        get_issues

        expect(assigns(:issues)).to include unescaped_parameter_value
        expect(assigns(:issues)).to include request_forgery_timing_attack
      end

      def get_issues
        get :index,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project
          }
      end
    end

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

      it "returns #{http_status[:success]} for admin" do
        sign_in(admin)
        go(id: unescaped_parameter_value.to_param)

        expect(response).to have_gitlab_http_status http_status[:success]
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

      before do
        sign_in(user)
        project.add_developer(user)
      end

      it_behaves_like 'restricted action', success: 200
      it_behaves_like 'update invalid issuable', Issue

      context 'changing the assignee' do
        it 'limits the attributes exposed on the assignee' do
          assignee = create(:user)
          project.add_developer(assignee)

          update_issue(issue_params: { assignee_ids: [assignee.id] })

          expect(json_response['assignees'].first.keys)
            .to match_array(%w(id name username avatar_url state web_url))
        end
      end

      context 'Akismet is enabled' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          stub_application_setting(recaptcha_enabled: true)
        end

        context 'when an issue is not identified as spam' do
          before do
            expect_next_instance_of(AkismetService) do |akismet_service|
              expect(akismet_service).to receive_messages(spam?: false)
            end
          end

          it 'normally updates the issue' do
            expect { update_issue(issue_params: { title: 'Foo' }) }.to change { issue.reload.title }.to('Foo')
          end
        end

        context 'when an issue is identified as spam' do
          context 'when captcha is not verified' do
            before do
              expect_next_instance_of(AkismetService) do |akismet_service|
                expect(akismet_service).to receive_messages(spam?: true)
              end
            end

            context 'when allow_possible_spam feature flag is false' do
              before do
                stub_feature_flags(allow_possible_spam: false)
              end

              it 'rejects an issue recognized as a spam' do
                expect { update_issue }.not_to change { issue.reload.title }
              end

              it 'rejects an issue recognized as a spam when recaptcha disabled' do
                stub_application_setting(recaptcha_enabled: false)

                expect { update_issue }.not_to change { issue.reload.title }
              end

              it 'creates a spam log' do
                expect { update_issue(issue_params: { title: 'Spam title' }) }
                  .to log_spam(title: 'Spam title', noteable_type: 'Issue')
              end

              it 'renders recaptcha_html json response' do
                update_issue

                expect(json_response).to have_key('recaptcha_html')
              end

              it 'returns 200 status' do
                update_issue

                expect(response).to have_gitlab_http_status(200)
              end
            end

            context 'when allow_possible_spam feature flag is true' do
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

                expect(response).to have_gitlab_http_status(200)
              end
            end
          end

          context 'when captcha is verified' do
            let(:spammy_title) { 'Whatever' }
            let!(:spam_logs) { create_list(:spam_log, 2, user: user, title: spammy_title) }

            def update_verified_issue
              update_issue(
                issue_params: { title: spammy_title },
                additional_params: { spam_log_id: spam_logs.last.id, recaptcha_verification: true })
            end

            it 'returns 200 status' do
              expect(response).to have_gitlab_http_status(200)
            end

            it 'accepts an issue after recaptcha is verified' do
              expect { update_verified_issue }.to change { issue.reload.title }.to(spammy_title)
            end

            it 'marks spam log as recaptcha_verified' do
              expect { update_verified_issue }.to change { SpamLog.last.recaptcha_verified }.from(false).to(true)
            end

            it 'does not mark spam log as recaptcha_verified when it does not belong to current_user' do
              spam_log = create(:spam_log)

              expect { update_issue(issue_params: { spam_log_id: spam_log.id, recaptcha_verification: true }) }
                .not_to change { SpamLog.last.recaptcha_verified }
            end
          end
        end
      end
    end

    describe 'GET #show' do
      it_behaves_like 'restricted action', success: 200

      def go(id:)
        get :show,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: id
          }
      end

      it 'avoids (most) N+1s loading labels', :request_store do
        label = create(:label, project: project).to_reference
        labels = create_list(:label, 10, project: project).map(&:to_reference)
        issue = create(:issue, project: project, description: 'Test issue')

        control_count = ActiveRecord::QueryRecorder.new { issue.update(description: [issue.description, label].join(' ')) }.count

        # Follow-up to get rid of this `2 * label.count` requirement: https://gitlab.com/gitlab-org/gitlab-foss/issues/52230
        expect { issue.update(description: [issue.description, labels].join(' ')) }
          .not_to exceed_query_limit(control_count + 2 * labels.count)
      end
    end

    describe 'GET #realtime_changes' do
      it_behaves_like 'restricted action', success: 200

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
      it_behaves_like 'restricted action', success: 200

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
    def post_new_issue(issue_attrs = {}, additional_params = {})
      sign_in(user)
      project = create(:project, :public)
      project.add_developer(user)

      post :create, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        issue: { title: 'Title', description: 'Description' }.merge(issue_attrs)
      }.merge(additional_params)

      project.issues.first
    end

    context 'resolving discussions in MergeRequest' do
      let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
      let(:merge_request) { discussion.noteable }
      let(:project) { merge_request.source_project }

      before do
        project.add_maintainer(user)
        sign_in user
      end

      let(:merge_request_params) do
        { merge_request_to_resolve_discussions_of: merge_request.iid }
      end

      def post_issue(issue_params, other_params: {})
        post :create, params: { namespace_id: project.namespace.to_param, project_id: project, issue: issue_params, merge_request_to_resolve_discussions_of: merge_request.iid }.merge(other_params)
      end

      it 'creates an issue for the project' do
        expect { post_issue({ title: 'Hello' }) }.to change { project.issues.reload.size }.by(1)
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
          post_issue({ title: 'Hello' }, other_params: { discussion_to_resolve: discussion.id })
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

    context 'Akismet is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'when an issue is not identified as spam' do
        before do
          stub_feature_flags(allow_possible_spam: false)

          expect_next_instance_of(AkismetService) do |akismet_service|
            expect(akismet_service).to receive_messages(spam?: false)
          end
        end

        it 'creates an issue' do
          expect { post_new_issue(title: 'Some title') }.to change(Issue, :count)
        end
      end

      context 'when an issue is identified as spam' do
        context 'when captcha is not verified' do
          def post_spam_issue
            post_new_issue(title: 'Spam Title', description: 'Spam lives here')
          end

          before do
            expect_next_instance_of(AkismetService) do |akismet_service|
              expect(akismet_service).to receive_messages(spam?: true)
            end
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it 'rejects an issue recognized as a spam' do
              expect { post_spam_issue }.not_to change(Issue, :count)
            end

            it 'creates a spam log' do
              expect { post_spam_issue }
                .to log_spam(title: 'Spam Title', noteable_type: 'Issue', recaptcha_verified: false)
            end

            it 'does not create an issue when it is not valid' do
              expect { post_new_issue(title: '') }.not_to change(Issue, :count)
            end

            it 'does not create an issue when recaptcha is not enabled' do
              stub_application_setting(recaptcha_enabled: false)

              expect { post_spam_issue }.not_to change(Issue, :count)
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it 'creates an issue recognized as spam' do
              expect { post_spam_issue }.to change(Issue, :count)
            end

            it 'creates a spam log' do
              expect { post_spam_issue }
                .to log_spam(title: 'Spam Title', noteable_type: 'Issue', recaptcha_verified: false)
            end

            it 'does not create an issue when it is not valid' do
              expect { post_new_issue(title: '') }.not_to change(Issue, :count)
            end
          end
        end

        context 'when captcha is verified' do
          let!(:spam_logs) { create_list(:spam_log, 2, user: user, title: 'Title') }

          def post_verified_issue
            post_new_issue({}, { spam_log_id: spam_logs.last.id, recaptcha_verification: true } )
          end

          before do
            expect(controller).to receive_messages(verify_recaptcha: true)
          end

          it 'accepts an issue after recaptcha is verified' do
            expect { post_verified_issue }.to change(Issue, :count)
          end

          it 'marks spam log as recaptcha_verified' do
            expect { post_verified_issue }.to change { SpamLog.last.recaptcha_verified }.from(false).to(true)
          end

          it 'does not mark spam log as recaptcha_verified when it does not belong to current_user' do
            spam_log = create(:spam_log)

            expect { post_new_issue({}, { spam_log_id: spam_log.id, recaptcha_verification: true } ) }
              .not_to change { SpamLog.last.recaptcha_verified }
          end
        end
      end
    end

    context 'user agent details are saved' do
      before do
        request.env['action_dispatch.remote_ip'] = '127.0.0.1'
      end

      it 'creates a user agent detail' do
        expect { post_new_issue }.to change(UserAgentDetail, :count).by(1)
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
        expect { subject }.to change(Issue, :count)
      end

      it 'creates a sentry issue' do
        expect { subject }.to change(SentryIssue, :count)
      end

      it 'with existing issue it will not create an issue' do
        post_new_issue(sentry_issue_attributes: { sentry_issue_identifier: 1234567 })

        expect { subject }.not_to change(Issue, :count)
      end
    end
  end

  describe 'POST #mark_as_spam' do
    context 'properly submits to Akismet' do
      before do
        expect_next_instance_of(AkismetService) do |akismet_service|
          expect(akismet_service).to receive_messages(submit_spam: true)
        end
        expect_next_instance_of(ApplicationSetting) do |setting|
          expect(setting).to receive_messages(akismet_enabled: true)
        end
      end

      def post_spam
        admin = create(:admin)
        create(:user_agent_detail, subject: issue)
        project.add_maintainer(admin)
        sign_in(admin)
        post :mark_as_spam, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: issue.iid
        }
      end

      it 'updates issue' do
        post_spam
        expect(issue.submittable_as_spam?).to be_falsey
      end
    end
  end

  describe "DELETE #destroy" do
    context "when the user is a developer" do
      before do
        sign_in(user)
      end

      it "rejects a developer to destroy an issue" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when the user is owner" do
      let(:owner)     { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project)   { create(:project, namespace: namespace) }

      before do
        sign_in(owner)
      end

      it "deletes the issue" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, destroy_confirm: true }

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to(/The issue was successfully deleted\./)
      end

      it "deletes the issue" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, destroy_confirm: true }

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to(/The issue was successfully deleted\./)
      end

      it "prevents deletion if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to('Destroy confirmation not provided for issue')
      end

      it "prevents deletion in JSON format if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, format: 'json' }

        expect(response).to have_gitlab_http_status(422)
        expect(json_response).to eq({ 'errors' => 'Destroy confirmation not provided for issue' })
      end

      it 'delegates the update of the todos count cache to TodoService' do
        expect_any_instance_of(TodoService).to receive(:destroy_target).with(issue).once

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: issue.iid, destroy_confirm: true }
      end
    end
  end

  describe 'POST #toggle_award_emoji' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    subject do
      post(:toggle_award_emoji, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: issue.iid,
        name: emoji_name
      })
    end

    let(:emoji_name) { 'thumbsup' }

    it "toggles the award emoji" do
      expect do
        subject
      end.to change { issue.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
    end

    it "removes the already awarded emoji" do
      create(:award_emoji, awardable: issue, name: emoji_name, user: user)

      expect { subject }.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_gitlab_http_status(200)
    end

    it 'marks Todos on the Issue as done' do
      todo = create(:todo, target: issue, project: project, user: user)

      subject

      expect(todo.reload).to be_done
    end
  end

  describe 'POST create_merge_request' do
    let(:target_project_id) { nil }
    let(:project) { create(:project, :repository, :public) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'creates a new merge request' do
      expect { create_merge_request }.to change(project.merge_requests, :count).by(1)
    end

    it 'render merge request as json' do
      create_merge_request

      expect(response).to match_response_schema('merge_request')
    end

    it 'is not available when the project is archived' do
      project.update!(archived: true)

      create_merge_request

      expect(response).to have_gitlab_http_status(404)
    end

    it 'is not available for users who cannot create merge requests' do
      sign_in(create(:user))

      create_merge_request

      expect(response).to have_gitlab_http_status(404)
    end

    context 'target_project_id is set' do
      let(:target_project) { fork_project(project, user, repository: true) }
      let(:target_project_id) { target_project.id }

      context 'create_confidential_merge_request feature is enabled' do
        before do
          stub_feature_flags(create_confidential_merge_request: true)
        end

        it 'creates a new merge request', :sidekiq_might_not_need_inline do
          expect { create_merge_request }.to change(target_project.merge_requests, :count).by(1)
        end
      end

      context 'create_confidential_merge_request feature is disabled' do
        before do
          stub_feature_flags(create_confidential_merge_request: false)
        end

        it 'creates a new merge request' do
          expect { create_merge_request }.to change(project.merge_requests, :count).by(1)
        end
      end
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
    let(:project) { create(:project, :public) }
    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

    context 'unauthorized' do
      it 'returns 404 for guests' do
        sign_out(:user)

        import_csv

        expect(response).to have_gitlab_http_status :not_found
      end

      it 'returns 404 for project members with reporter role' do
        sign_in(user)
        project.add_reporter(user)

        import_csv

        expect(response).to have_gitlab_http_status :not_found
      end
    end

    context 'authorized' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it "returns 302 for project members with developer role" do
        import_csv

        expect(flash[:notice]).to eq(_("Your issues are being imported. Once finished, you'll get a confirmation email."))
        expect(response).to redirect_to(project_issues_path(project))
      end

      it "shows error when upload fails" do
        expect_next_instance_of(UploadService) do |upload_service|
          expect(upload_service).to receive(:execute).and_return(nil)
        end

        import_csv

        expect(flash[:alert]).to include(_('File upload error.'))
        expect(response).to redirect_to(project_issues_path(project))
      end
    end

    def import_csv
      post :import_csv, params: { namespace_id: project.namespace.to_param,
                                  project_id: project.to_param,
                                  file: file }
    end
  end

  describe 'GET #discussions' do
    let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }
    context 'when authenticated' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      context do
        it_behaves_like 'discussions provider' do
          let!(:author) { create(:user) }
          let!(:project) { create(:project) }

          let!(:issue) { create(:issue, project: project, author: user) }

          let!(:note_on_issue1) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: create(:user)) }
          let!(:note_on_issue2) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: create(:user)) }

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

        expect(json_response.first.keys).to match_array(%w[id reply_id expanded notes diff_discussion discussion_path individual_note resolvable resolved resolved_at resolved_by resolved_by_push commit_id for_commit project_id])
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
          .not_to exceed_query_limit(control)
      end

      context 'when user is setting notes filters' do
        let(:issuable) { issue }
        let(:issuable_parent) { project }
        let!(:discussion_note) { create(:discussion_note_on_issue, :system, noteable: issuable, project: project) }

        it_behaves_like 'issuable notes filter'
      end

      context 'with cross-reference system note', :request_store do
        let(:new_issue) { create(:issue) }
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

          control_count = ActiveRecord::QueryRecorder.new do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }
          end.count

          RequestStore.clear!

          create_list(:discussion_note_on_issue, 2, :system, noteable: issue, project: issue.project, note: cross_reference)

          expect { get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid } }.not_to exceed_query_limit(control_count)
        end
      end

      context 'private project' do
        let!(:branch_note) { create(:discussion_note_on_issue, :system, noteable: issue, project: project) }
        let!(:commit_note) { create(:discussion_note_on_issue, :system, noteable: issue, project: project) }
        let!(:branch_note_meta) { create(:system_note_metadata, note: branch_note, action: "branch") }
        let!(:commit_note_meta) { create(:system_note_metadata, note: commit_note, action: "commit") }

        context 'user is allowed access' do
          before do
            project.add_user(user, :maintainer)
          end

          it 'displays all available notes' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            expect(json_response.length).to eq(3)
          end
        end

        context 'user is a guest' do
          let(:json_response_note_ids) do
            json_response.collect { |discussion| discussion["notes"] }.flatten
              .collect { |note| note["id"].to_i }
          end

          before do
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

  context 'private project with token authentication' do
    let(:private_project) { create(:project, :private) }

    it_behaves_like 'authenticates sessionless user', :index, :atom, ignore_incrementing: true do
      before do
        default_params.merge!(project_id: private_project, namespace_id: private_project.namespace)

        private_project.add_maintainer(user)
      end
    end

    it_behaves_like 'authenticates sessionless user', :calendar, :ics, ignore_incrementing: true do
      before do
        default_params.merge!(project_id: private_project, namespace_id: private_project.namespace)

        private_project.add_maintainer(user)
      end
    end
  end

  context 'public project with token authentication' do
    let(:public_project) { create(:project, :public) }

    it_behaves_like 'authenticates sessionless user', :index, :atom, public: true do
      before do
        default_params.merge!(project_id: public_project, namespace_id: public_project.namespace)
      end
    end

    it_behaves_like 'authenticates sessionless user', :calendar, :ics, public: true do
      before do
        default_params.merge!(project_id: public_project, namespace_id: public_project.namespace)
      end
    end
  end
end
