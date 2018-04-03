require('spec_helper')

describe Projects::IssuesController do
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

          get :index, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when GitLab issues enabled' do
        it 'renders the "index" template' do
          get :index, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:index)
        end
      end
    end

    context 'internal issue tracker' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it_behaves_like "issuables list meta-data", :issue

      it "returns index" do
        get :index, namespace_id: project.namespace, project_id: project

        expect(response).to have_gitlab_http_status(200)
      end

      it "returns 301 if request path doesn't match project path" do
        get :index, namespace_id: project.namespace, project_id: project.path.upcase

        expect(response).to redirect_to(project_issues_path(project))
      end

      it "returns 404 when issues are disabled" do
        project.issues_enabled = false
        project.save!

        get :index, namespace_id: project.namespace, project_id: project
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with page param' do
      let(:last_page) { project.issues.page().total_pages }
      let!(:issue_list) { create_list(:issue, 2, project: project) }

      before do
        sign_in(user)
        project.add_developer(user)
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'redirects to last_page if page number is larger than number of pages' do
        get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          page: (last_page + 1).to_param

        expect(response).to redirect_to(namespace_project_issues_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end

      it 'redirects to specified page' do
        get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          page: last_page.to_param

        expect(assigns(:issues).current_page).to eq(last_page)
        expect(response).to have_gitlab_http_status(200)
      end

      it 'does not redirect to external sites when provided a host field' do
        external_host = "www.example.com"
        get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          page: (last_page + 1).to_param,
          host: external_host

        expect(response).to redirect_to(namespace_project_issues_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end

      it 'does not use pagination if disabled' do
        allow(controller).to receive(:pagination_disabled?).and_return(true)

        get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          page: (last_page + 1).to_param

        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:issues).size).to eq(2)
      end
    end
  end

  describe 'GET #new' do
    it 'redirects to signin if not logged in' do
      get :new, namespace_id: project.namespace, project_id: project

      expect(flash[:notice]).to eq 'Please sign in to create the new issue.'
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'internal issue tracker' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it 'builds a new issue' do
        get :new, namespace_id: project.namespace, project_id: project

        expect(assigns(:issue)).to be_a_new(Issue)
      end

      it 'fills in an issue for a merge request' do
        project_with_repository = create(:project, :repository)
        project_with_repository.add_developer(user)
        mr = create(:merge_request_with_diff_notes, source_project: project_with_repository)

        get :new, namespace_id: project_with_repository.namespace, project_id: project_with_repository, merge_request_to_resolve_discussions_of: mr.iid

        expect(assigns(:issue).title).not_to be_empty
        expect(assigns(:issue).description).not_to be_empty
      end

      it 'fills in an issue for a discussion' do
        note = create(:note_on_merge_request, project: project)

        get :new, namespace_id: project.namespace.path, project_id: project, merge_request_to_resolve_discussions_of: note.noteable.iid, discussion_to_resolve: note.discussion_id

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

          get :new, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when GitLab issues enabled' do
        it 'renders the "new" template' do
          get :new, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'Redirect after sign in' do
    context 'with an AJAX request' do
      it 'does not store the visited URL' do
        xhr :get,
          :show,
          format: :json,
          namespace_id: project.namespace,
          project_id: project,
          id: issue.iid

        expect(session['user_return_to']).to be_blank
      end
    end

    context 'without an AJAX request' do
      it 'stores the visited URL' do
        get :show,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: issue.iid

        expect(session['user_return_to']).to eq("/#{project.namespace.to_param}/#{project.to_param}/issues/#{issue.iid}")
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
          format: :json,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: issue.iid,
          move_to_project_id: another_project.id
      end
    end
  end

  describe 'PUT #update' do
    subject do
      put :update,
        namespace_id: project.namespace,
        project_id: project,
        id: issue.to_param,
        issue: { title: 'New title' }, format: :json
    end

    before do
      sign_in(user)
    end

    context 'when user has access to update issue' do
      before do
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
          allow_any_instance_of(SpamService).to receive(:check_for_spam?).and_return(true)
          allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
        end

        it 'renders json with recaptcha_html' do
          subject

          expect(JSON.parse(response.body)).to have_key('recaptcha_html')
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
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: id
    end

    context 'when an issue was edited' do
      before do
        project.add_developer(user)

        issue.update!(last_edited_by: user, last_edited_at: issue.created_at + 1.minute)

        sign_in(user)
      end

      it 'returns last edited time' do
        go(id: issue.iid)

        data = JSON.parse(response.body)

        expect(data).to include('updated_at')
        expect(data['updated_at']).to eq(issue.last_edited_at.to_time.iso8601)
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
          namespace_id: project.namespace.to_param,
          project_id: project
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

        put :update, params
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

          body = JSON.parse(response.body)

          expect(body['assignees'].first.keys)
            .to match_array(%w(id name username avatar_url state web_url))
        end
      end

      context 'Akismet is enabled' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          stub_application_setting(recaptcha_enabled: true)
          allow_any_instance_of(SpamService).to receive(:check_for_spam?).and_return(true)
        end

        context 'when an issue is not identified as spam' do
          before do
            allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)
            allow_any_instance_of(AkismetService).to receive(:spam?).and_return(false)
          end

          it 'normally updates the issue' do
            expect { update_issue(issue_params: { title: 'Foo' }) }.to change { issue.reload.title }.to('Foo')
          end
        end

        context 'when an issue is identified as spam' do
          before do
            allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
          end

          context 'when captcha is not verified' do
            before do
              allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)
            end

            it 'rejects an issue recognized as a spam' do
              expect { update_issue }.not_to change { issue.reload.title }
            end

            it 'rejects an issue recognized as a spam when recaptcha disabled' do
              stub_application_setting(recaptcha_enabled: false)

              expect { update_issue }.not_to change { issue.reload.title }
            end

            it 'creates a spam log' do
              update_issue(issue_params: { title: 'Spam title' })

              spam_logs = SpamLog.all

              expect(spam_logs.count).to eq(1)
              expect(spam_logs.first.title).to eq('Spam title')
              expect(spam_logs.first.recaptcha_verified).to be_falsey
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

          context 'when captcha is verified' do
            let(:spammy_title) { 'Whatever' }
            let!(:spam_logs) { create_list(:spam_log, 2, user: user, title: spammy_title) }

            def update_verified_issue
              update_issue(
                issue_params: { title: spammy_title },
                additional_params: { spam_log_id: spam_logs.last.id, recaptcha_verification: true })
            end

            before do
              allow_any_instance_of(described_class).to receive(:verify_recaptcha)
                .and_return(true)
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
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id
      end
    end

    describe 'GET #realtime_changes' do
      it_behaves_like 'restricted action', success: 200

      def go(id:)
        get :realtime_changes,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id
      end
    end

    describe 'GET #edit' do
      it_behaves_like 'restricted action', success: 200

      def go(id:)
        get :edit,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id
      end
    end

    describe 'PUT #update' do
      it_behaves_like 'restricted action', success: 302

      def go(id:)
        put :update,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id,
          issue: { title: 'New title' }
      end
    end
  end

  describe 'POST #create' do
    def post_new_issue(issue_attrs = {}, additional_params = {})
      sign_in(user)
      project = create(:project, :public)
      project.add_developer(user)

      post :create, {
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
        project.add_master(user)
        sign_in user
      end

      let(:merge_request_params) do
        { merge_request_to_resolve_discussions_of: merge_request.iid }
      end

      def post_issue(issue_params, other_params: {})
        post :create, { namespace_id: project.namespace.to_param, project_id: project, issue: issue_params, merge_request_to_resolve_discussions_of: merge_request.iid }.merge(other_params)
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

        expect(flash[:notice]).to eq('Resolved all discussions.')
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
          expect(flash[:notice]).to eq('Resolved 1 discussion.')
        end
      end
    end

    context 'Akismet is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
        allow_any_instance_of(SpamService).to receive(:check_for_spam?).and_return(true)
      end

      context 'when an issue is not identified as spam' do
        before do
          allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)
          allow_any_instance_of(AkismetService).to receive(:spam?).and_return(false)
        end

        it 'does not create an issue' do
          expect { post_new_issue(title: '') }.not_to change(Issue, :count)
        end
      end

      context 'when an issue is identified as spam' do
        before do
          allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
        end

        context 'when captcha is not verified' do
          def post_spam_issue
            post_new_issue(title: 'Spam Title', description: 'Spam lives here')
          end

          before do
            allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)
          end

          it 'rejects an issue recognized as a spam' do
            expect { post_spam_issue }.not_to change(Issue, :count)
          end

          it 'creates a spam log' do
            post_spam_issue
            spam_logs = SpamLog.all

            expect(spam_logs.count).to eq(1)
            expect(spam_logs.first.title).to eq('Spam Title')
            expect(spam_logs.first.recaptcha_verified).to be_falsey
          end

          it 'does not create an issue when it is not valid' do
            expect { post_new_issue(title: '') }.not_to change(Issue, :count)
          end

          it 'does not create an issue when recaptcha is not enabled' do
            stub_application_setting(recaptcha_enabled: false)

            expect { post_spam_issue }.not_to change(Issue, :count)
          end
        end

        context 'when captcha is verified' do
          let!(:spam_logs) { create_list(:spam_log, 2, user: user, title: 'Title') }

          def post_verified_issue
            post_new_issue({}, { spam_log_id: spam_logs.last.id, recaptcha_verification: true } )
          end

          before do
            allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(true)
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
  end

  describe 'POST #mark_as_spam' do
    context 'properly submits to Akismet' do
      before do
        allow_any_instance_of(AkismetService).to receive_messages(submit_spam: true)
        allow_any_instance_of(ApplicationSetting).to receive_messages(akismet_enabled: true)
      end

      def post_spam
        admin = create(:admin)
        create(:user_agent_detail, subject: issue)
        project.add_master(admin)
        sign_in(admin)
        post :mark_as_spam, {
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
        delete :destroy, namespace_id: project.namespace, project_id: project, id: issue.iid
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
        delete :destroy, namespace_id: project.namespace, project_id: project, id: issue.iid

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to(/The issue was successfully deleted\./)
      end

      it 'delegates the update of the todos count cache to TodoService' do
        expect_any_instance_of(TodoService).to receive(:destroy_target).with(issue).once

        delete :destroy, namespace_id: project.namespace, project_id: project, id: issue.iid
      end
    end
  end

  describe 'POST #toggle_award_emoji' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    it "toggles the award emoji" do
      expect do
        post(:toggle_award_emoji, namespace_id: project.namespace,
                                  project_id: project, id: issue.iid, name: "thumbsup")
      end.to change { issue.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'POST create_merge_request' do
    let(:project) { create(:project, :repository) }

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

    def create_merge_request
      post :create_merge_request, namespace_id: project.namespace.to_param,
                                  project_id: project.to_param,
                                  id: issue.to_param,
                                  format: :json
    end
  end

  describe 'GET #discussions' do
    let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }
    context 'when authenticated' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      it 'returns discussion json' do
        get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid

        expect(json_response.first.keys).to match_array(%w[id reply_id expanded notes diff_discussion individual_note resolvable resolved])
<<<<<<< HEAD
      end

      it 'filters notes that the user should not see' do
        get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid

        expect(JSON.parse(response.body).count).to eq(1)
      end
    end

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
            expect(notes).to include(a_hash_including('id' => system_note.id))
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
            expect(notes).not_to include(a_hash_including('id' => system_note.id))
          end
        end
      end

      context 'when authenticated' do
        before do
          sign_in(user)
        end

        %i(reporter developer master).each do |access|
          it_behaves_like 'user can see confidential issue', access
        end

        it_behaves_like 'user cannot see confidential issue', :guest
      end

      context 'when unauthenticated' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'user cannot see confidential issue', Gitlab::Access::NO_ACCESS
=======
>>>>>>> upstream/master
      end

      context 'with cross-reference system note', :request_store do
        let(:new_issue) { create(:issue) }
        let(:cross_reference) { "mentioned in #{new_issue.to_reference(issue.project)}" }

        before do
          create(:discussion_note_on_issue, :system, noteable: issue, project: issue.project, note: cross_reference)
        end

        it 'does not result in N+1 queries' do
          # Instantiate the controller variables to ensure QueryRecorder has an accurate base count
          get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid

          RequestStore.clear!

          control_count = ActiveRecord::QueryRecorder.new do
            get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid
          end.count

          RequestStore.clear!

          create_list(:discussion_note_on_issue, 2, :system, noteable: issue, project: issue.project, note: cross_reference)

          expect { get :discussions, namespace_id: project.namespace, project_id: project, id: issue.iid }.not_to exceed_query_limit(control_count)
        end
      end
    end
  end
end
