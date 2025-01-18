# frozen_string_literal: true

require('spec_helper')

RSpec.describe ProjectsController, feature_category: :groups_and_projects do
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

      context 'with managable group' do
        context 'when managable_group_count is 1' do
          before do
            group.add_owner(user)
          end

          it 'renders the template' do
            get :new

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('new')
          end
        end

        context 'when managable_group_count is 0' do
          context 'when create_projects on personal namespace is allowed' do
            before do
              allow(user).to receive(:can_create_project?).and_return(true)
            end

            it 'renders the template' do
              get :new

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template('new')
            end
          end

          context 'when create_projects on personal namespace is not allowed' do
            before do
              stub_application_setting(allow_project_creation_for_guest_and_below: false)
            end

            it 'responds with status 404' do
              get :new

              expect(response).to have_gitlab_http_status(:not_found)
              expect(response).not_to render_template('new')
            end
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

          expect(response).to render_template('projects/_issues')
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
      let_it_be(:empty_project) { create(:project, :public) }

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
            expect(response).to render_template('projects/no_repo')
          end
        end
      end
    end

    context 'when project default branch is corrupted' do
      let_it_be(:corrupted_project) { create(:project, :small_repo, :public) }

      before do
        sign_in(user)

        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:root_ref).and_raise(Gitlab::Git::CommandError, 'get default branch')
        end
      end

      it 'renders the missing default branch view' do
        get :show, params: { namespace_id: corrupted_project.namespace, id: corrupted_project }

        expect(response).to render_template('projects/missing_default_branch')
        expect(response).to have_gitlab_http_status(:service_unavailable)
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

      it "renders files even with invalid license" do
        invalid_license = ::Gitlab::Git::DeclaredLicense.new(key: 'woozle', name: 'woozle wuzzle')

        controller.instance_variable_set(:@project, public_project)
        expect(public_project.repository).to receive(:license).and_return(invalid_license).at_least(:once)

        get_show

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('_files')
        expect(response.body).to have_content('woozle wuzzle')
      end

      describe 'tracking events', :snowplow do
        before do
          allow(controller).to receive(:current_user).and_return(user)
          get_show
        end

        it 'tracks page views' do
          expect_snowplow_event(
            category: 'project_overview',
            action: 'render',
            user: user,
            project: public_project
          )
        end

        context 'when the project is importing' do
          let_it_be(:public_project) { create(:project, :public, :import_scheduled) }

          it 'does not track page views' do
            expect_no_snowplow_event(
              category: 'project_overview',
              action: 'render',
              user: user,
              project: public_project
            )
          end
        end
      end

      describe "PUC highlighting" do
        render_views

        before do
          expect(controller).to receive(:find_routable!).and_return(public_project)
        end

        context "option is enabled" do
          it "adds the highlighting class" do
            expect(public_project).to receive(:warn_about_potentially_unwanted_characters?).and_return(true)

            get_show

            expect(response.body).to have_css(".project-highlight-puc")
          end
        end

        context "option is disabled" do
          it "doesn't add the highlighting class" do
            expect(public_project).to receive(:warn_about_potentially_unwanted_characters?).and_return(false)

            get_show

            expect(response.body).not_to have_css(".project-highlight-puc")
          end
        end
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
          project.team.add_member(user, :guest) if user_type == :member
          sign_in(user) unless user_type == :anonymous
        end

        it 'returns the expected status' do
          get :show, params: { namespace_id: project.namespace, id: project }, format: :git

          expect(response).to have_gitlab_http_status(expected_status)
          expect(response).to redirect_to(send(expected_redirect)) if expected_status == :found
        end
      end
    end

    context 'redirection from http://someproject.git?ref=master' do
      it 'redirects to project without .git extension' do
        get :show, params: { namespace_id: public_project.namespace, id: public_project, ref: 'master', path: '/.gitlab-ci.yml' }, format: :git

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_path(public_project, ref: 'master', path: '/.gitlab-ci.yml'))
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

  describe 'POST create' do
    subject { post :create, params: { project: params } }

    before do
      sign_in(user)
    end

    context 'on import' do
      let(:params) do
        {
          path: 'foo',
          description: 'bar',
          namespace_id: user.namespace.id,
          import_url: project.http_url_to_repo
        }
      end

      context 'when import by url is disabled' do
        before do
          stub_application_setting(import_sources: [])
        end

        it 'does not create project and reports an error' do
          expect { subject }.not_to change { Project.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when import by url is enabled' do
        before do
          stub_application_setting(import_sources: ['git'])
        end

        it 'creates project' do
          expect { subject }.to change { Project.count }

          expect(response).to have_gitlab_http_status(:redirect)
        end
      end
    end
  end

  describe 'GET edit' do
    it 'allows an admin user to access the page', :enable_admin_mode do
      sign_in(create(:user, :admin))

      get :edit, params: { namespace_id: project.namespace.path, id: project.path }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'sets the badge API endpoint' do
      sign_in(user)
      project.add_maintainer(user)

      get :edit, params: { namespace_id: project.namespace.path, id: project.path }

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

        post :archive, params: { namespace_id: project.namespace.path, id: project.path }
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
    let(:housekeeping_service_dbl) { instance_double(::Repositories::HousekeepingService) }
    let(:params) do
      {
        namespace_id: project.namespace.path,
        id: project.path,
        prune: prune
      }
    end

    let(:prune) { nil }
    let_it_be(:project) { create(:project, group: group) }
    let(:housekeeping) { ::Repositories::HousekeepingService.new(project) }

    subject { post :housekeeping, params: params }

    context 'when authenticated as owner' do
      before do
        group.add_owner(user)
        sign_in(user)

        allow(::Repositories::HousekeepingService).to receive(:new).with(project, :eager).and_return(housekeeping)
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

      it 'logs an audit event' do
        expect(housekeeping).to receive(:execute).once.and_yield

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(a_hash_including(
          name: 'manually_trigger_housekeeping',
          author: user,
          scope: project,
          target: project,
          message: "Housekeeping task: eager"
        ))

        subject
      end

      context 'and requesting prune' do
        let(:prune) { true }

        it 'enqueues pruning' do
          allow(::Repositories::HousekeepingService).to receive(:new).with(project, :prune).and_return(housekeeping_service_dbl)
          expect(housekeeping_service_dbl).to receive(:execute)

          subject
          expect(response).to have_gitlab_http_status(:found)
        end
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
          original_repository_path = project.repository.relative_path

          expect { update_project path: 'renamed_path' }.to change { project.reload.path }
          expect(project.path).to include 'renamed_path'

          assign_repository_path = assigns(:repository).relative_path

          expect(original_repository_path).to include(hashed_storage_path)
          expect(assign_repository_path).to include(hashed_storage_path)
        end

        it "upgrades and move project to hashed storage when project was originally legacy" do
          skip if project.hashed_storage?(:repository)

          hashed_storage_path = Storage::Hashed.new(project).disk_path
          original_repository_path = project.repository.relative_path

          expect { update_project path: 'renamed_path' }.to change { project.reload.path }
          expect(project.path).to include 'renamed_path'

          assign_repository_path = assigns(:repository).relative_path

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

        let(:message) { 'UpdateProject|Cannot rename project because it contains container registry tags!' }

        shared_examples 'not allowing the rename of the project' do
          it 'does not allow to rename the project' do
            expect { update_project path: 'renamed_path' }
              .not_to change { project.reload.path }

            expect(controller).to set_flash[:alert].to(s_(message))
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when Gitlab API is not supported' do
          before do
            allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
          end

          it_behaves_like 'not allowing the rename of the project'
        end

        context 'when Gitlab API is supported' do
          before do
            allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
          end

          it 'allows the rename of the project' do
            allow(ContainerRegistry::GitlabApiClient).to receive(:rename_base_repository_path).and_return(:accepted, :ok)

            expect { update_project path: 'renamed_path' }
                .to change { project.reload.path }

            expect(project.path).to eq('renamed_path')
            expect(response).to have_gitlab_http_status(:found)
          end

          context 'when rename base repository dry run in the registry fails' do
            let(:message) { 'UpdateProject|UpdateProject|Cannot rename project, the container registry path rename validation failed: Bad Request' }

            before do
              allow(ContainerRegistry::GitlabApiClient).to receive(:rename_base_repository_path).and_return(:bad_request)
            end

            it_behaves_like 'not allowing the rename of the project'
          end
        end
      end

      it 'updates Fast Forward Merge attributes' do
        controller.instance_variable_set(:@project, project)

        params = {
          merge_method: :ff
        }

        put :update, params: { namespace_id: project.namespace, id: project.id, project: params }

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
          put :update, params: { namespace_id: project.namespace, id: project.id, project: params }
        end.not_to change { project.namespace.reload }
      end

      def update_project(**parameters)
        put :update, params: { namespace_id: project.namespace.path, id: project.path, project: parameters }
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
          put :update, params: {
            namespace_id: project.namespace, id: project, project: { description: 'Hello world' }
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
                enforce_auth_checks_on_uploads: boolean_value,
                emails_enabled: boolean_value
              }
            }
          }

          project.reload

          expect(project.show_default_award_emojis?).to eq(result)
          expect(project.enforce_auth_checks_on_uploads?).to eq(result)
          expect(project.emails_enabled?).to eq(result)
          expect(project.emails_disabled?).to eq(!result)
        end
      end
    end

    context 'with project feature attributes' do
      let(:initial_value) { ProjectFeature::PRIVATE }
      let(:update_to) { ProjectFeature::ENABLED }

      before do
        project.project_feature.update!(feature_access_level => initial_value)
      end

      def update_project_feature
        put :update, params: {
          namespace_id: project.namespace,
          id: project.path,
          project: {
            project_feature_attributes: {
              feature_access_level.to_s => update_to
            }
          }
        }
      end

      shared_examples 'feature update success' do
        it 'updates access level successfully' do
          expect { update_project_feature }.to change {
            project.reload.project_feature.public_send(feature_access_level)
          }.from(initial_value).to(update_to)
        end
      end

      shared_examples 'feature update failure' do
        it 'cannot update access level' do
          expect { update_project_feature }.not_to change {
            project.reload.project_feature.public_send(feature_access_level)
          }
        end
      end

      where(:feature_access_level) do
        %i[
          metrics_dashboard_access_level
          container_registry_access_level
          environments_access_level
          feature_flags_access_level
          releases_access_level
          monitor_access_level
          infrastructure_access_level
          model_experiments_access_level
          model_registry_access_level
        ]
      end

      with_them do
        it_behaves_like 'feature update success'
      end
    end

    context 'project topics' do
      context 'on updates with topics of the same name (case insensitive)' do
        it 'returns 200, with alert about update failing' do
          put :update, params: {
            namespace_id: project.namespace,
            id: project.path,
            project: {
              topics: 'smoketest, SMOKETEST'
            }
          }

          expect(response).to be_successful
          expect(flash[:alert]).to eq('Project could not be updated!')
        end
      end
    end
  end

  describe '#transfer', :enable_admin_mode do
    render_views

    let(:project) { create(:project) }

    let_it_be(:admin) { create(:admin) }
    let_it_be(:new_namespace) { create(:namespace) }

    shared_examples 'project namespace is not changed' do |flash_message|
      it 'project namespace is not changed' do
        controller.instance_variable_set(:@project, project)
        sign_in(admin)

        old_namespace = project.namespace

        put :transfer, params: {
          namespace_id: old_namespace.path, new_namespace_id: new_namespace_id, id: project.path
        }, format: :js

        project.reload

        expect(project.namespace).to eq(old_namespace)
        expect(response).to redirect_to(edit_project_path(project))
        expect(flash[:alert]).to eq flash_message
      end
    end

    it 'updates namespace' do
      sign_in(admin)

      put :transfer, params: {
        namespace_id: project.namespace.path, new_namespace_id: new_namespace.id, id: project.path
      }, format: :js

      project.reload

      expect(project.namespace).to eq(new_namespace)
      expect(response).to redirect_to(edit_project_path(project))
    end

    context 'when new namespace is empty' do
      let(:new_namespace_id) { nil }

      it_behaves_like 'project namespace is not changed', s_('TransferProject|Please select a new namespace for your project.')
    end

    context 'when new namespace is the same as the current namespace' do
      let(:new_namespace_id) { project.namespace.id }

      it_behaves_like 'project namespace is not changed', s_('TransferProject|Project is already in this namespace.')
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
      expect(flash[:toast]).to eq(format(_("Project '%{project_name}' is being deleted."), project_name: project.full_name))
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

      post :toggle_star, params: { namespace_id: public_project.namespace, id: public_project }
      expect(user.starred?(public_project)).to be_truthy

      post :toggle_star, params: { namespace_id: public_project.namespace, id: public_project }
      expect(user.starred?(public_project)).to be_falsey
    end

    it "does nothing if user is not signed in" do
      post :toggle_star, params: { namespace_id: project.namespace, id: public_project }
      expect(user.starred?(public_project)).to be_falsey

      post :toggle_star, params: { namespace_id: project.namespace, id: public_project }
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
          delete :remove_fork, params: {
            namespace_id: forked_project.namespace.to_param, id: forked_project.to_param
          }, format: :js

          expect(forked_project.reload.forked?).to be_falsey
          expect(flash[:notice]).to eq(s_('The fork relationship has been removed.'))
          expect(response).to redirect_to(edit_project_path(forked_project))
        end
      end

      context 'when project not forked' do
        let(:unforked_project) { create(:project, namespace: user.namespace) }

        it 'does nothing if project was not forked' do
          delete :remove_fork, params: {
            namespace_id: unforked_project.namespace, id: unforked_project
          }, format: :js

          expect(flash[:notice]).to be_nil
          expect(response).to redirect_to(edit_project_path(unforked_project))
        end
      end
    end

    it "does nothing if user is not signed in" do
      delete :remove_fork, params: {
        namespace_id: project.namespace, id: project
      }, format: :js

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

    it 'uses gitaly pagination' do
      expected_params = ActionController::Parameters.new(ref: '123456', per_page: 100).permit!

      expect_next_instance_of(BranchesFinder, project.repository, expected_params) do |finder|
        expect(finder).to receive(:execute).with(gitaly_pagination: true).and_call_original
      end

      expect_next_instance_of(TagsFinder, project.repository, expected_params) do |finder|
        expect(finder).to receive(:execute).with(gitaly_pagination: true).and_call_original
      end

      get :refs, params: { namespace_id: project.namespace, id: project, ref: "123456" }
    end

    context 'when gitaly is unavailable' do
      before do
        expect_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute).and_raise(Gitlab::Git::CommandError, 'something went wrong')
        end
      end

      it 'responds with 503 error' do
        get :refs, params: { namespace_id: project.namespace, id: project, ref: "123456" }

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(json_response['error']).to eq 'Unable to load refs'
      end
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

    context 'when input params are invalid' do
      let(:request) { get :refs, params: { namespace_id: project.namespace, id: project, ref: { invalid: :format } } }

      it 'does not break' do
        request

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when sort param is invalid' do
      let(:request) { get :refs, params: { namespace_id: project.namespace, id: project, sort: 'invalid' } }

      it 'uses default sort by name' do
        request

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['Branches']).to include('master')
        expect(json_response['Tags']).to include('v1.0.0')
        expect(json_response['Commits']).to be_nil
      end
    end
  end

  describe 'POST #preview_markdown' do
    before do
      sign_in(user)
    end

    it 'renders json in a correct format' do
      post :preview_markdown, params: { namespace_id: public_project.namespace, project_id: public_project, text: '*Markdown* text' }

      expect(json_response.keys).to match_array(%w[body references])
    end

    context 'when not authorized' do
      let(:private_project) { create(:project, :private) }

      it 'returns 404' do
        post :preview_markdown, params: { namespace_id: private_project.namespace, project_id: private_project, text: '*Markdown* text' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'state filter on references' do
      let_it_be(:issue) { create(:issue, :closed, project: public_project) }

      let(:merge_request) { create(:merge_request, :closed, target_project: public_project) }

      it 'renders JSON body with state filter for issues' do
        post :preview_markdown, params: {
                                  namespace_id: public_project.namespace,
                                  project_id: public_project,
                                  text: issue.to_reference
                                }

        expect(json_response['body']).to match(/\##{issue.iid} \(closed\)/)
      end

      it 'renders JSON body with state filter for MRs' do
        post :preview_markdown, params: {
                                  namespace_id: public_project.namespace,
                                  project_id: public_project,
                                  text: merge_request.to_reference
                                }

        expect(json_response['body']).to match(/!#{merge_request.iid} \(closed\)/)
      end
    end

    context 'when path parameter is provided' do
      let(:project_with_repo) { create(:project, :repository) }
      let(:preview_markdown_params) do
        {
          namespace_id: project_with_repo.namespace.full_path,
          project_id: project_with_repo.path,
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
          namespace_id: project_with_repo.namespace.full_path,
          project_id: project_with_repo.path,
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
        allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
          allow(strategy)
            .to receive(:increment)
            .and_return(Gitlab::ApplicationRateLimiter.rate_limits["project_#{action}".to_sym][:threshold].call + 1)
        end
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

          expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
        end

        context 'when the project storage_size exceeds the application setting max_export_size' do
          it 'returns 302 with alert' do
            stub_application_setting(max_export_size: 1)
            project.statistics.update!(lfs_objects_size: 2.megabytes, repository_size: 2.megabytes)

            post action, params: { namespace_id: project.namespace, id: project }

            expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
            expect(flash[:alert]).to include('The project size exceeds the export limit.')
          end
        end

        context 'when the project storage_size does not exceed the application setting max_export_size' do
          it 'returns 302 without alert' do
            stub_application_setting(max_export_size: 1)
            project.statistics.update!(lfs_objects_size: 0.megabytes, repository_size: 0.megabytes)

            post action, params: { namespace_id: project.namespace, id: project }

            expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
            expect(flash[:alert]).to be_nil
          end
        end

        context 'when application setting max_export_size is not set' do
          it 'returns 302 without alert' do
            project.statistics.update!(lfs_objects_size: 2.megabytes, repository_size: 2.megabytes)

            post action, params: { namespace_id: project.namespace, id: project }

            expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
            expect(flash[:alert]).to be_nil
          end
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

      context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_rate_limiting do
        include_examples 'rate limits project export endpoint'
      end
    end

    describe '#download_export', :clean_gitlab_redis_rate_limiting do
      let(:project) { create(:project, service_desk_enabled: false, creator: user) }
      let!(:export) { create(:import_export_upload, project: project, user: user) }
      let(:action) { :download_export }

      context 'object storage enabled' do
        context 'when project export is enabled' do
          it 'returns 200' do
            get action, params: { namespace_id: project.namespace, id: project }

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when project export file is absent' do
          it 'alerts the user and returns 302' do
            project.export_file(user).file.delete

            get action, params: { namespace_id: project.namespace, id: project }

            expect(flash[:alert]).to include('file containing the export is not available yet')
            expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
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

        context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_rate_limiting do
          before do
            allow_next_instance_of(Gitlab::ApplicationRateLimiter::BaseStrategy) do |strategy|
              allow(strategy)
                .to receive(:increment)
                .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:project_download_export][:threshold].call + 1)
            end
          end

          it 'prevents requesting project export' do
            post action, params: { namespace_id: project.namespace, id: project }

            expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end
        end

        context 'applies correct scope when throttling', :clean_gitlab_redis_rate_limiting do
          before do
            stub_application_setting(project_download_export_limit: 1)

            travel_to Date.current.beginning_of_day
          end

          after do
            travel_back
          end

          it 'applies throttle per namespace' do
            expect(Gitlab::ApplicationRateLimiter)
              .to receive(:throttled?)
              .with(:project_download_export, scope: [user, project.namespace])

            post action, params: { namespace_id: project.namespace, id: project }
          end

          it 'throttles downloads within same namespaces' do
            # simulate prior request to the same namespace, which increments the rate limit counter for that scope
            Gitlab::ApplicationRateLimiter.throttled?(:project_download_export, scope: [user, project.namespace])

            get action, params: { namespace_id: project.namespace, id: project }
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end

          it 'allows downloads from different namespaces' do
            # simulate prior request to a different namespace, which increments the rate limit counter for that scope
            Gitlab::ApplicationRateLimiter.throttled?(:project_download_export,
              scope: [user, create(:project, :with_export).namespace])

            get action, params: { namespace_id: project.namespace, id: project }
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    describe '#remove_export' do
      let(:action) { :remove_export }

      context 'when project export is enabled' do
        it 'returns 302' do
          post action, params: { namespace_id: project.namespace, id: project }

          expect(response).to redirect_to(edit_project_path(project, anchor: 'js-project-advanced-settings'))
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

      context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_rate_limiting do
        include_examples 'rate limits project export endpoint'
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

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to render_template(:show)
      expect(response).to render_template(layout: :xml)
      expect(assigns(:events)).to eq([event])
    end

    it 'filters by calling event.visible_to_user?' do
      get :show, format: :atom, params: { id: public_project, namespace_id: public_project.namespace }

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to render_template(:show)
      expect(response).to render_template(layout: :xml)
      expect(assigns(:events)).to eq([event])
    end
  end

  it 'updates Service Desk attributes' do
    project.add_maintainer(user)
    sign_in(user)
    allow(Gitlab::Email::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?) { true }
    params = {
      service_desk_enabled: true
    }

    put :update, params: { namespace_id: project.namespace, id: project, project: params }
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
