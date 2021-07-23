# frozen_string_literal: true

require('spec_helper')

RSpec.describe ProjectsController do
  include ExternalAuthorizationServiceHelpers
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project, reload: true) { create(:project, :with_export, service_desk_enabled: false) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:jpg) { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt) { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }

  describe 'GET new' do
    context 'with an authenticated user' do
      let_it_be(:group) { create(:group) }

      before do
        sign_in(user)
      end

      context 'when namespace_id param is present' do
        context 'when user has access to the namespace' do
          it 'renders the template' do
            group.add_owner(user)

            get :new, params: { namespace_id: group.id }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('new')
          end
        end

        context 'when user does not have access to the namespace' do
          it 'responds with status 404' do
            get :new, params: { namespace_id: group.id }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response).not_to render_template('new')
          end
        end
      end
    end
  end

  describe 'GET index' do
    context 'as a user' do
      it 'redirects to root page' do
        sign_in(user)

        get :index

        expect(response).to redirect_to(root_path)
      end
    end

    context 'as a guest' do
      it 'redirects to Explore page' do
        get :index

        expect(response).to redirect_to(explore_root_path)
      end
    end
  end

  describe "GET #activity as JSON" do
    include DesignManagementTestHelpers
    render_views

    let_it_be(:project) { create(:project, :public, issues_access_level: ProjectFeature::PRIVATE) }

    before do
      enable_design_management
      create(:event, :created, project: project, target: create(:issue))

      sign_in(user)

      request.cookies[:event_filter] = 'all'
    end

    context 'when user has permission to see the event' do
      before do
        project.add_developer(user)
      end

      def get_activity(project)
        get :activity, params: { namespace_id: project.namespace, id: project, format: :json }
      end

      it 'returns count' do
        get_activity(project)

        expect(json_response['count']).to eq(1)
      end

      context 'design events are visible' do
        include DesignManagementTestHelpers
        let(:other_project) { create(:project, namespace: user.namespace) }

        before do
          enable_design_management
          create(:design_event, project: project)
          request.cookies[:event_filter] = EventFilter::DESIGNS
        end

        it 'returns correct count' do
          get_activity(project)

          expect(json_response['count']).to eq(1)
        end
      end
    end

    context 'when user has no permission to see the event' do
      it 'filters out invisible event' do
        get :activity, params: { namespace_id: project.namespace, id: project, format: :json }

        expect(json_response['html']).to eq("\n")
        expect(json_response['count']).to eq(0)
      end
    end
  end

  describe "GET show" do
    context "user not project member" do
      before do
        sign_in(user)
      end

      context "user does not have access to project" do
        let(:private_project) { create(:project, :private) }

        it "does not initialize notification setting" do
          get :show, params: { namespace_id: private_project.namespace, id: private_project }
          expect(assigns(:notification_setting)).to be_nil
        end
      end

      context "user has access to project" do
        before do
          expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
        end

        context "and does not have notification setting" do
          it "initializes notification as disabled" do
            get :show, params: { namespace_id: public_project.namespace, id: public_project }
            expect(assigns(:notification_setting).level).to eq("global")
          end
        end

        context "and has notification setting" do
          before do
            setting = user.notification_settings_for(public_project)
            setting.level = :watch
            setting.save!
          end

          it "shows current notification setting" do
            get :show, params: { namespace_id: public_project.namespace, id: public_project }
            expect(assigns(:notification_setting).level).to eq("watch")
          end
        end
      end

      describe "when project repository is disabled" do
        render_views

        before do
          project.add_developer(user)
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)
        end

        it 'shows wiki homepage' do
          get :show, params: { namespace_id: project.namespace, id: project }

          expect(response).to render_template('projects/_wiki')
        end

        it 'shows issues list page if wiki is disabled' do
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
          create(:issue, project: project)

          get :show, params: { namespace_id: project.namespace, id: project }

          expect(response).to render_template('projects/issues/_issues')
          expect(assigns(:issuable_meta_data)).not_to be_nil
        end

        it 'shows activity page if wiki and issues are disabled' do
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get :show, params: { namespace_id: project.namespace, id: project }

          expect(response).to render_template("projects/_activity")
        end

        it 'shows activity if enabled by user' do
          user.update_attribute(:project_view, 'activity')

          get :show, params: { namespace_id: project.namespace, id: project }

          expect(response).to render_template("projects/_activity")
        end
      end
    end

    context "project with empty repo" do
      let_it_be(:empty_project) { create(:project_empty_repo, :public) }

      before do
        sign_in(user)

        allow(controller).to receive(:record_experiment_user)
      end

      context 'when user can push to default branch', :experiment do
        let(:user) { empty_project.owner }

        it 'creates an "view_project_show" experiment tracking event' do
          expect(experiment(:empty_repo_upload)).to track(
            :view_project_show,
            property: 'empty'
          ).on_next_instance

          get :show, params: { namespace_id: empty_project.namespace, id: empty_project }
        end
      end

      User.project_views.keys.each do |project_view|
        context "with #{project_view} view set" do
          before do
            user.update!(project_view: project_view)

            get :show, params: { namespace_id: empty_project.namespace, id: empty_project }
          end

          it "renders the empty project view" do
            expect(response).to render_template('empty')
          end
        end
      end
    end

    context "project with broken repo" do
      let_it_be(:empty_project) { create(:project_broken_repo, :public) }

      before do
        sign_in(user)
      end

      User.project_views.keys.each do |project_view|
        context "with #{project_view} view set" do
          before do
            user.update!(project_view: project_view)

            get :show, params: { namespace_id: empty_project.namespace, id: empty_project }
          end

          it "renders the empty project view" do
            allow(Project).to receive(:repo).and_raise(Gitlab::Git::Repository::NoRepository)

            expect(response).to render_template('projects/no_repo')
          end
        end
      end
    end

    context "rendering default project view" do
      let_it_be(:public_project) { create(:project, :public, :repository) }

      render_views

      def get_show
        get :show, params: { namespace_id: public_project.namespace, id: public_project }
      end

      it "renders the activity view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('activity')

        get_show

        expect(response).to render_template('_activity')
      end

      it "renders the files view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('files')

        get_show

        expect(response).to render_template('_files')
      end

      it "renders the readme view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('readme')

        get_show

        expect(response).to render_template('_readme')
      end

      it 'does not make Gitaly requests', :request_store, :clean_gitlab_redis_cache do
        # Warm up to populate repository cache
        get_show
        RequestStore.clear!

        expect { get_show }.not_to change { Gitlab::GitalyClient.get_request_count }
      end
    end

    context "when the url contains .atom" do
      let(:public_project_with_dot_atom) { build(:project, :public, name: 'my.atom', path: 'my.atom') }

      it 'expects an error creating the project' do
        expect(public_project_with_dot_atom).not_to be_valid
      end
    end

    context 'when the project is pending deletions' do
      it 'renders a 404 error' do
        project = create(:project, pending_delete: true)
        sign_in(user)

        get :show, params: { namespace_id: project.namespace, id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'redirection from http://someproject.git' do
      where(:user_type, :project_visibility, :expected_redirect) do
        :anonymous | :public   | :redirect_to_project
        :anonymous | :internal | :redirect_to_signup
        :anonymous | :private  | :redirect_to_signup

        :signed_in | :public   | :redirect_to_project
        :signed_in | :internal | :redirect_to_project
        :signed_in | :private  | nil

        :member | :public   | :redirect_to_project
        :member | :internal | :redirect_to_project
        :member | :private  | :redirect_to_project
      end

      with_them do
        let(:redirect_to_signup) { new_user_session_path }
        let(:redirect_to_project) { project_path(project) }

        let(:expected_status) { expected_redirect ? :found : :not_found }

        before do
          project.update!(visibility: project_visibility.to_s)
          project.team.add_user(user, :guest) if user_type == :member
          sign_in(user) unless user_type == :anonymous
        end

        it 'returns the expected status' do
          get :show, params: { namespace_id: project.namespace, id: project }, format: :git

          expect(response).to have_gitlab_http_status(expected_status)
          expect(response).to redirect_to(send(expected_redirect)) if expected_status == :found
        end
      end
    end

    context 'when project is moved and git format is requested' do
      let(:old_path) { project.path + 'old' }

      before do
        project.redirect_routes.create!(path: "#{project.namespace.full_path}/#{old_path}")

        project.add_developer(user)
        sign_in(user)
      end

      it 'redirects to new project path' do
        get :show, params: { namespace_id: project.namespace, id: old_path }, format: :git

        expect(response).to redirect_to(project_path(project, format: :git))
      end
    end

    context 'when the project is forked and has a repository', :request_store do
      let(:public_project) { create(:project, :public, :repository) }
      let(:other_user) { create(:user) }

      render_views

      before do
        # View the project as a user that does not have any rights
        sign_in(other_user)

        fork_project(public_project)
      end

      it 'does not increase the number of queries when the project is forked' do
        expected_query = /#{public_project.fork_network.find_forks_in(other_user.namespace).to_sql}/

        expect { get(:show, params: { namespace_id: public_project.namespace, id: public_project }) }
          .not_to exceed_query_limit(2).for_query(expected_query)
      end
    end
  end

  describe 'GET edit' do
    it 'allows an admin user to access the page', :enable_admin_mode do
      sign_in(create(:user, :admin))

      get :edit,
          params: {
            namespace_id: project.namespace.path,
            id: project.path
          }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'sets the badge API endpoint' do
      sign_in(user)
      project.add_maintainer(user)

      get :edit,
          params: {
            namespace_id: project.namespace.path,
            id: project.path
          }

      expect(assigns(:badge_api_endpoint)).not_to be_nil
    end
  end

  describe 'POST #archive' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      sign_in(user)
    end

    context 'for a user with the ability to archive a project' do
      before do
        group.add_owner(user)

        post :archive, params: {
          namespace_id: project.namespace.path,
          id: project.path
        }
      end

      it 'archives the project' do
        expect(project.reload.archived?).to be_truthy
      end

      it 'redirects to projects path' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_path(project))
      end
    end

    context 'for a user that does not have the ability to archive a project' do
      before do
        project.add_maintainer(user)

        post :archive, params: {
          namespace_id: project.namespace.path,
          id: project.path
        }
      end

      it 'does not archive the project' do
        expect(project.reload.archived?).to be_falsey
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #unarchive' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :archived, group: group) }

    before do
      sign_in(user)
    end

    context 'for a user with the ability to unarchive a project' do
      before do
        group.add_owner(user)

        post :unarchive, params: {
          namespace_id: project.namespace.path,
          id: project.path
        }
      end

      it 'unarchives the project' do
        expect(project.reload.archived?).to be_falsey
      end

      it 'redirects to projects path' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_path(project))
      end
    end

    context 'for a user that does not have the ability to unarchive a project' do
      before do
        project.add_maintainer(user)

        post :unarchive, params: {
          namespace_id: project.namespace.path,
          id: project.path
        }
      end

      it 'does not unarchive the project' do
        expect(project.reload.archived?).to be_truthy
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#housekeeping' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:housekeeping) { Repositories::HousekeepingService.new(project) }

    context 'when authenticated as owner' do
      before do
        group.add_owner(user)
        sign_in(user)

        allow(Repositories::HousekeepingService).to receive(:new).with(project, :gc).and_return(housekeeping)
      end

      it 'forces a full garbage collection' do
        expect(housekeeping).to receive(:execute).once

        post :housekeeping,
             params: {
               namespace_id: project.namespace.path,
               id: project.path
             }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when authenticated as developer' do
      let(:developer) { create(:user) }

      before do
        group.add_developer(developer)
      end

      it 'does not execute housekeeping' do
        expect(housekeeping).not_to receive(:execute)

        post :housekeeping,
             params: {
               namespace_id: project.namespace.path,
               id: project.path
             }

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe "#update", :enable_admin_mode do
    render_views

    let(:admin) { create(:admin) }

    before do
      sign_in(admin)
    end

    shared_examples_for 'updating a project' do
      context 'when there is a conflicting project path' do
        let(:random_name) { "project-#{SecureRandom.hex(8)}" }
        let!(:conflict_project) { create(:project, name: random_name, path: random_name, namespace: project.namespace) }

        it 'does not show any references to the conflicting path' do
          expect { update_project(path: random_name) }.not_to change { project.reload.path }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).not_to include(random_name)
        end
      end

      context 'when only renaming a project path' do
        it "doesnt change the disk_path when using hashed storage" do
          skip unless project.hashed_storage?(:repository)

          hashed_storage_path = ::Storage::Hashed.new(project).disk_path
          original_repository_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path
          end

          expect { update_project path: 'renamed_path' }.to change { project.reload.path }
          expect(project.path).to include 'renamed_path'

          assign_repository_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            assigns(:repository).path
          end

          expect(original_repository_path).to include(hashed_storage_path)
          expect(assign_repository_path).to include(hashed_storage_path)
        end

        it "upgrades and move project to hashed storage when project was originally legacy" do
          skip if project.hashed_storage?(:repository)

          hashed_storage_path = Storage::Hashed.new(project).disk_path
          original_repository_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path
          end

          expect { update_project path: 'renamed_path' }.to change { project.reload.path }
          expect(project.path).to include 'renamed_path'

          assign_repository_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            assigns(:repository).path
          end

          expect(original_repository_path).not_to include(hashed_storage_path)
          expect(assign_repository_path).to include(hashed_storage_path)
          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when project has container repositories with tags' do
        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: /image/, tags: %w[rc1])
          create(:container_repository, project: project, name: :image)
        end

        it 'does not allow to rename the project' do
          expect { update_project path: 'renamed_path' }
            .not_to change { project.reload.path }

          expect(controller).to set_flash[:alert].to(s_('UpdateProject|Cannot rename project because it contains container registry tags!'))
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it 'updates Fast Forward Merge attributes' do
        controller.instance_variable_set(:@project, project)

        params = {
          merge_method: :ff
        }

        put :update,
            params: {
              namespace_id: project.namespace,
              id: project.id,
              project: params
            }

        expect(response).to have_gitlab_http_status(:found)
        params.each do |param, value|
          expect(project.public_send(param)).to eq(value)
        end
      end

      it 'does not update namespace' do
        controller.instance_variable_set(:@project, project)

        params = {
          namespace_id: 'test'
        }

        expect do
          put :update,
            params: {
              namespace_id: project.namespace,
              id: project.id,
              project: params
            }
        end.not_to change { project.namespace.reload }
      end

      def update_project(**parameters)
        put :update,
            params: {
              namespace_id: project.namespace.path,
              id: project.path,
              project: parameters
            }
      end
    end

    context 'hashed storage' do
      let_it_be(:project) { create(:project, :repository) }

      it_behaves_like 'updating a project'
    end

    context 'legacy storage' do
      let_it_be(:project) { create(:project, :repository, :legacy_storage) }

      it_behaves_like 'updating a project'
    end

    context 'as maintainer' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it_behaves_like 'unauthorized when external service denies access' do
        subject do
          put :update,
              params: {
                namespace_id: project.namespace,
                id: project,
                project: { description: 'Hello world' }
              }
          project.reload
        end

        it 'updates when the service allows access' do
          external_service_allow_access(user, project)

          expect { subject }.to change(project, :description)
        end

        it 'does not update when the service rejects access' do
          external_service_deny_access(user, project)

          expect { subject }.not_to change(project, :description)
        end
      end
    end

    context 'when updating boolean values on project_settings' do
      using RSpec::Parameterized::TableSyntax

      where(:boolean_value, :result) do
        '1'   | true
        '0'   | false
        1     | true
        0     | false
        true  | true
        false | false
      end

      with_them do
        it 'updates project settings attributes accordingly' do
          put :update, params: {
            namespace_id: project.namespace,
            id: project.path,
            project: {
              project_setting_attributes: {
                show_default_award_emojis: boolean_value,
                allow_editing_commit_messages: boolean_value
              }
            }
          }

          project.reload

          expect(project.show_default_award_emojis?).to eq(result)
          expect(project.allow_editing_commit_messages?).to eq(result)
        end
      end
    end
  end

  describe '#transfer', :enable_admin_mode do
    render_views

    let_it_be(:project, reload: true) { create(:project) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:new_namespace) { create(:namespace) }

    it 'updates namespace' do
      sign_in(admin)

      put :transfer,
          params: {
            namespace_id: project.namespace.path,
            new_namespace_id: new_namespace.id,
            id: project.path
          },
          format: :js

      project.reload

      expect(project.namespace).to eq(new_namespace)
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when new namespace is empty' do
      it 'project namespace is not changed' do
        controller.instance_variable_set(:@project, project)
        sign_in(admin)

        old_namespace = project.namespace

        put :transfer,
            params: {
              namespace_id: old_namespace.path,
              new_namespace_id: nil,
              id: project.path
            },
            format: :js

        project.reload

        expect(project.namespace).to eq(old_namespace)
        expect(response).to have_gitlab_http_status(:ok)
        expect(flash[:alert]).to eq s_('TransferProject|Please select a new namespace for your project.')
      end
    end
  end

  describe "#destroy", :enable_admin_mode do
    let_it_be(:admin) { create(:admin) }

    it "redirects to the dashboard", :sidekiq_might_not_need_inline do
      controller.instance_variable_set(:@project, project)
      sign_in(admin)

      orig_id = project.id
      delete :destroy, params: { namespace_id: project.namespace, id: project }

      expect { Project.find(orig_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(dashboard_projects_path)
    end

    context "when the project is forked" do
      let(:project) { create(:project, :repository) }
      let(:forked_project) { fork_project(project, nil, repository: true) }
      let(:merge_request) do
        create(:merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "closes all related merge requests", :sidekiq_might_not_need_inline do
        project.merge_requests << merge_request
        sign_in(admin)

        delete :destroy, params: { namespace_id: forked_project.namespace, id: forked_project }

        expect(merge_request.reload.state).to eq('closed')
      end
    end
  end

  describe 'PUT #new_issuable_address for issue' do
    subject do
      put :new_issuable_address,
        params: {
          namespace_id: project.namespace,
          id: project,
          issuable_type: 'issue'
        }
      user.reload
    end

    before do
      sign_in(user)
      project.add_developer(user)
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
    end

    it 'has http status 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'changes the user incoming email token' do
      expect { subject }.to change { user.incoming_email_token }
    end

    it 'changes projects new issue address' do
      expect { subject }.to change { project.new_issuable_address(user, 'issue') }
    end
  end

  describe 'PUT #new_issuable_address for merge request' do
    subject do
      put :new_issuable_address,
        params: {
          namespace_id: project.namespace,
          id: project,
          issuable_type: 'merge_request'
        }
      user.reload
    end

    before do
      sign_in(user)
      project.add_developer(user)
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
    end

    it 'has http status 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'changes the user incoming email token' do
      expect { subject }.to change { user.incoming_email_token }
    end

    it 'changes projects new merge request address' do
      expect { subject }.to change { project.new_issuable_address(user, 'merge_request') }
    end
  end

  describe "POST #toggle_star" do
    it "toggles star if user is signed in" do
      sign_in(user)
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           params: {
             namespace_id: public_project.namespace,
             id: public_project
           })
      expect(user.starred?(public_project)).to be_truthy
      post(:toggle_star,
           params: {
             namespace_id: public_project.namespace,
             id: public_project
           })
      expect(user.starred?(public_project)).to be_falsey
    end

    it "does nothing if user is not signed in" do
      post(:toggle_star,
           params: {
             namespace_id: project.namespace,
             id: public_project
           })
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           params: {
             namespace_id: project.namespace,
             id: public_project
           })
      expect(user.starred?(public_project)).to be_falsey
    end
  end

  describe "DELETE remove_fork" do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      context 'with forked project' do
        let(:forked_project) { fork_project(create(:project, :public), user) }

        it 'removes fork from project' do
          delete(:remove_fork,
              params: {
                namespace_id: forked_project.namespace.to_param,
                id: forked_project.to_param
              },
              format: :js)

          expect(forked_project.reload.forked?).to be_falsey
          expect(flash[:notice]).to eq(s_('The fork relationship has been removed.'))
          expect(response).to render_template(:remove_fork)
        end
      end

      context 'when project not forked' do
        let(:unforked_project) { create(:project, namespace: user.namespace) }

        it 'does nothing if project was not forked' do
          delete(:remove_fork,
              params: {
                namespace_id: unforked_project.namespace,
                id: unforked_project
              },
              format: :js)

          expect(flash[:notice]).to be_nil
          expect(response).to render_template(:remove_fork)
        end
      end
    end

    it "does nothing if user is not signed in" do
      delete(:remove_fork,
          params: {
            namespace_id: project.namespace,
            id: project
          },
          format: :js)
      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe "GET refs" do
    let_it_be(:project) { create(:project, :public, :repository) }

    it 'gets a list of branches and tags' do
      get :refs, params: { namespace_id: project.namespace, id: project, sort: 'updated_desc' }

      expect(json_response['Branches']).to include('master')
      expect(json_response['Tags']).to include('v1.0.0')
      expect(json_response['Commits']).to be_nil
    end

    it "gets a list of branches, tags and commits" do
      get :refs, params: { namespace_id: project.namespace, id: project, ref: "123456" }

      expect(json_response["Branches"]).to include("master")
      expect(json_response["Tags"]).to include("v1.0.0")
      expect(json_response["Commits"]).to include("123456")
    end

    context "when preferred language is Japanese" do
      before do
        user.update!(preferred_language: 'ja')
        sign_in(user)
      end

      it "gets a list of branches, tags and commits" do
        get :refs, params: { namespace_id: project.namespace, id: project, ref: "123456" }

        expect(json_response["Branches"]).to include("master")
        expect(json_response["Tags"]).to include("v1.0.0")
        expect(json_response["Commits"]).to include("123456")
      end
    end

    context 'when private project' do
      let(:project) { create(:project, :repository) }

      context 'as a guest' do
        it 'renders forbidden' do
          user = create(:user)
          project.add_guest(user)

          sign_in(user)
          get :refs, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    before do
      sign_in(user)
    end

    it 'renders json in a correct format' do
      post :preview_markdown, params: { namespace_id: public_project.namespace, id: public_project, text: '*Markdown* text' }

      expect(json_response.keys).to match_array(%w(body references))
    end

    context 'when not authorized' do
      let(:private_project) { create(:project, :private) }

      it 'returns 404' do
        post :preview_markdown, params: { namespace_id: private_project.namespace, id: private_project, text: '*Markdown* text' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'state filter on references' do
      let_it_be(:issue) { create(:issue, :closed, project: public_project) }

      let(:merge_request) { create(:merge_request, :closed, target_project: public_project) }

      it 'renders JSON body with state filter for issues' do
        post :preview_markdown, params: {
                                  namespace_id: public_project.namespace,
                                  id: public_project,
                                  text: issue.to_reference
                                }

        expect(json_response['body']).to match(/\##{issue.iid} \(closed\)/)
      end

      it 'renders JSON body with state filter for MRs' do
        post :preview_markdown, params: {
                                  namespace_id: public_project.namespace,
                                  id: public_project,
                                  text: merge_request.to_reference
                                }

        expect(json_response['body']).to match(/\!#{merge_request.iid} \(closed\)/)
      end
    end

    context 'when path parameter is provided' do
      let(:project_with_repo) { create(:project, :repository) }
      let(:preview_markdown_params) do
        {
          namespace_id: project_with_repo.namespace,
          id: project_with_repo,
          text: "![](./logo-white.png)\n",
          path: 'files/images/README.md'
        }
      end

      before do
        project_with_repo.add_maintainer(user)
      end

      it 'renders JSON body with image links expanded' do
        expanded_path = "/#{project_with_repo.full_path}/-/raw/master/files/images/logo-white.png"

        post :preview_markdown, params: preview_markdown_params

        expect(json_response['body']).to include(expanded_path)
      end
    end

    context 'when path and ref parameters are provided' do
      let(:project_with_repo) { create(:project, :repository) }
      let(:preview_markdown_params) do
        {
          namespace_id: project_with_repo.namespace,
          id: project_with_repo,
          text: "![](./logo-white.png)\n",
          ref: 'other_branch',
          path: 'files/images/README.md'
        }
      end

      before do
        project_with_repo.add_maintainer(user)
        project_with_repo.repository.create_branch('other_branch')
      end

      it 'renders JSON body with image links expanded' do
        expanded_path = "/#{project_with_repo.full_path}/-/raw/other_branch/files/images/logo-white.png"

        post :preview_markdown, params: preview_markdown_params

        expect(json_response['body']).to include(expanded_path)
      end
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting the canonical path' do
        context "with exactly matching casing" do
          it "loads the project" do
            get :show, params: { namespace_id: public_project.namespace, id: public_project }

            expect(assigns(:project)).to eq(public_project)
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context "with different casing" do
          it "redirects to the normalized path" do
            get :show, params: { namespace_id: public_project.namespace, id: public_project.path.upcase }

            expect(assigns(:project)).to eq(public_project)
            expect(response).to redirect_to("/#{public_project.full_path}")
            expect(controller).not_to set_flash[:notice]
          end
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { public_project.redirect_routes.create!(path: "foo/bar") }

        it 'redirects to the canonical path' do
          get :show, params: { namespace_id: 'foo', id: 'bar' }

          expect(response).to redirect_to(public_project)
          expect(controller).to set_flash[:notice].to(project_moved_message(redirect_route, public_project))
        end

        it 'redirects to the canonical path (testing non-show action)' do
          get :refs, params: { namespace_id: 'foo', id: 'bar' }

          expect(response).to redirect_to(refs_project_path(public_project))
          expect(controller).to set_flash[:notice].to(project_moved_message(redirect_route, public_project))
        end
      end
    end

    context 'for a POST request' do
      context 'when requesting the canonical path with different casing' do
        it 'does not 404' do
          post :toggle_star, params: { namespace_id: public_project.namespace, id: public_project.path.upcase }

          expect(response).not_to have_gitlab_http_status(:not_found)
        end

        it 'does not redirect to the correct casing' do
          post :toggle_star, params: { namespace_id: public_project.namespace, id: public_project.path.upcase }

          expect(response).not_to have_gitlab_http_status(:moved_permanently)
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { public_project.redirect_routes.create!(path: "foo/bar") }

        it 'returns not found' do
          post :toggle_star, params: { namespace_id: 'foo', id: 'bar' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'for a DELETE request', :enable_admin_mode do
      before do
        sign_in(create(:admin))
      end

      context 'when requesting the canonical path with different casing' do
        it 'does not 404' do
          delete :destroy, params: { namespace_id: project.namespace, id: project.path.upcase }

          expect(response).not_to have_gitlab_http_status(:not_found)
        end

        it 'does not redirect to the correct casing' do
          delete :destroy, params: { namespace_id: project.namespace, id: project.path.upcase }

          expect(response).not_to have_gitlab_http_status(:moved_permanently)
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { project.redirect_routes.create!(path: "foo/bar") }

        it 'returns not found' do
          delete :destroy, params: { namespace_id: 'foo', id: 'bar' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'project export' do
    before do
      sign_in(user)

      project.add_maintainer(user)
    end

    shared_examples 'rate limits project export endpoint' do
      before do
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits["project_#{action}".to_sym][:threshold].call + 1)
      end

      it 'prevents requesting project export' do
        post action, params: { namespace_id: project.namespace, id: project }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end

    describe '#export' do
      let(:action) { :export }

      context 'when project export is enabled' do
        it 'returns 302' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when project export is disabled' do
        before do
          stub_application_setting(project_export_enabled?: false)
        end

        it 'returns 404' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_cache do
        include_examples 'rate limits project export endpoint'
      end
    end

    describe '#download_export', :clean_gitlab_redis_cache do
      let(:action) { :download_export }

      context 'object storage enabled' do
        context 'when project export is enabled' do
          it 'returns 302' do
            get action, params: { namespace_id: project.namespace, id: project }

            expect(response).to have_gitlab_http_status(:found)
          end
        end

        context 'when project export file is absent' do
          it 'alerts the user and returns 302' do
            project.export_file.file.delete

            get action, params: { namespace_id: project.namespace, id: project }

            expect(flash[:alert]).to include('file containing the export is not available yet')
            expect(response).to have_gitlab_http_status(:found)
          end
        end

        context 'when project export is disabled' do
          before do
            stub_application_setting(project_export_enabled?: false)
          end

          it 'returns 404' do
            get action, params: { namespace_id: project.namespace, id: project }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_cache do
          before do
            allow(Gitlab::ApplicationRateLimiter)
              .to receive(:increment)
              .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:project_download_export][:threshold].call + 1)
          end

          it 'prevents requesting project export' do
            post action, params: { namespace_id: project.namespace, id: project }

            expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end

          it 'applies correct scope when throttling' do
            expect(Gitlab::ApplicationRateLimiter)
              .to receive(:throttled?)
              .with(:project_download_export, scope: [user, project])

            post action, params: { namespace_id: project.namespace, id: project }
          end
        end
      end
    end

    describe '#remove_export' do
      let(:action) { :remove_export }

      context 'when project export is enabled' do
        it 'returns 302' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when project export is disabled' do
        before do
          stub_application_setting(project_export_enabled?: false)
        end

        it 'returns 404' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe '#generate_new_export' do
      let(:action) { :generate_new_export }

      context 'when project export is enabled' do
        it 'returns 302' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when project export is disabled' do
        before do
          stub_application_setting(project_export_enabled?: false)
        end

        it 'returns 404' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_cache do
        include_examples 'rate limits project export endpoint'
      end
    end
  end

  context 'private project with token authentication' do
    let_it_be(:private_project) { create(:project, :private) }

    it_behaves_like 'authenticates sessionless user', :show, :atom, ignore_incrementing: true do
      before do
        default_params.merge!(id: private_project, namespace_id: private_project.namespace)

        private_project.add_maintainer(user)
      end
    end
  end

  context 'public project with token authentication' do
    let_it_be(:public_project) { create(:project, :public) }

    it_behaves_like 'authenticates sessionless user', :show, :atom, public: true do
      before do
        default_params.merge!(id: public_project, namespace_id: public_project.namespace)
      end
    end
  end

  context 'GET show.atom' do
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:event) { create(:event, :commented, project: public_project, target: create(:note, project: public_project)) }
    let_it_be(:invisible_event) { create(:event, :commented, project: public_project, target: create(:note, :confidential, project: public_project)) }

    it 'filters by calling event.visible_to_user?' do
      expect(EventCollection).to receive_message_chain(:new, :to_a).and_return([event, invisible_event])
      expect(event).to receive(:visible_to_user?).and_return(true)
      expect(invisible_event).to receive(:visible_to_user?).and_return(false)

      get :show, format: :atom, params: { id: public_project, namespace_id: public_project.namespace }

      expect(response).to render_template('xml.atom')
      expect(assigns(:events)).to eq([event])
    end

    it 'filters by calling event.visible_to_user?' do
      get :show, format: :atom, params: { id: public_project, namespace_id: public_project.namespace }

      expect(response).to render_template('xml.atom')
      expect(assigns(:events)).to eq([event])
    end
  end

  describe 'GET resolve' do
    shared_examples 'resolvable endpoint' do
      it 'redirects to the project page' do
        get :resolve, params: { id: project.id }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_path(project))
      end
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when user has access to the project' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'resolvable endpoint'
      end

      context 'when user has no access to the project' do
        it 'gives 404 for existing project' do
          get :resolve, params: { id: project.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'gives 404 for non-existing project' do
        get :resolve, params: { id: '0' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'non authenticated user' do
      context 'with a public project' do
        let(:project) { public_project }

        it_behaves_like 'resolvable endpoint'
      end

      it 'gives 404 for private project' do
        get :resolve, params: { id: project.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  it 'updates Service Desk attributes' do
    project.add_maintainer(user)
    sign_in(user)
    allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
    params = {
      service_desk_enabled: true
    }

    put :update,
        params: {
          namespace_id: project.namespace,
          id: project,
          project: params
        }
    project.reload

    expect(response).to have_gitlab_http_status(:found)
    expect(project.service_desk_enabled).to eq(true)
  end

  def project_moved_message(redirect_route, project)
    "Project '#{redirect_route.path}' was moved to '#{project.full_path}'. Please update any links and bookmarks that may still have the old path."
  end

  describe 'GET #unfoldered_environment_names' do
    it 'shows the environment names of a public project to an anonymous user' do
      create(:environment, project: public_project, name: 'foo')

      get(
        :unfoldered_environment_names,
        params: { namespace_id: public_project.namespace, id: public_project, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(%w[foo])
    end

    it 'does not show environment names of a private project to anonymous users' do
      create(:environment, project: project, name: 'foo')

      get(
        :unfoldered_environment_names,
        params: { namespace_id: project.namespace, id: project, format: :json }
      )

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows environment names of a private project to a project member' do
      create(:environment, project: project, name: 'foo')
      project.add_developer(user)
      sign_in(user)

      get(
        :unfoldered_environment_names,
        params: { namespace_id: project.namespace, id: project, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(%w[foo])
    end

    it 'does not show environment names of a private project to a logged-in non-member' do
      create(:environment, project: project, name: 'foo')
      sign_in(user)

      get(
        :unfoldered_environment_names,
        params: { namespace_id: project.namespace, id: project, format: :json }
      )

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
