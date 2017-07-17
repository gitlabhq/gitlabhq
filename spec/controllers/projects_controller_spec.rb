require('spec_helper')

describe ProjectsController do
  let(:project) { create(:empty_project) }
  let(:public_project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:jpg) { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt) { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

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

  describe "GET show" do
    context "user not project member" do
      before do
        sign_in(user)
      end

      context "user does not have access to project" do
        let(:private_project) { create(:empty_project, :private) }

        it "does not initialize notification setting" do
          get :show, namespace_id: private_project.namespace, id: private_project
          expect(assigns(:notification_setting)).to be_nil
        end
      end

      context "user has access to project" do
        context "and does not have notification setting" do
          it "initializes notification as disabled" do
            get :show, namespace_id: public_project.namespace, id: public_project
            expect(assigns(:notification_setting).level).to eq("global")
          end
        end

        context "and has notification setting" do
          before do
            setting = user.notification_settings_for(public_project)
            setting.level = :watch
            setting.save
          end

          it "shows current notification setting" do
            get :show, namespace_id: public_project.namespace, id: public_project
            expect(assigns(:notification_setting).level).to eq("watch")
          end
        end
      end

      describe "when project repository is disabled" do
        render_views

        before do
          project.team << [user, :developer]
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)
        end

        it 'shows wiki homepage' do
          get :show, namespace_id: project.namespace, id: project

          expect(response).to render_template('projects/_wiki')
        end

        it 'shows issues list page if wiki is disabled' do
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
          create(:issue, project: project)

          get :show, namespace_id: project.namespace, id: project

          expect(response).to render_template('projects/issues/_issues')
          expect(assigns(:issuable_meta_data)).not_to be_nil
        end

        it 'shows customize workflow page if wiki and issues are disabled' do
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get :show, namespace_id: project.namespace, id: project

          expect(response).to render_template("projects/_customize_workflow")
        end

        it 'shows activity if enabled by user' do
          user.update_attribute(:project_view, 'activity')

          get :show, namespace_id: project.namespace, id: project

          expect(response).to render_template("projects/_activity")
        end
      end
    end

    context "project with empty repo" do
      let(:empty_project) { create(:project_empty_repo, :public) }

      before do
        sign_in(user)
      end

      User.project_views.keys.each do |project_view|
        context "with #{project_view} view set" do
          before do
            user.update_attributes(project_view: project_view)

            get :show, namespace_id: empty_project.namespace, id: empty_project
          end

          it "renders the empty project view" do
            expect(response).to render_template('empty')
          end
        end
      end
    end

    context "project with broken repo" do
      let(:empty_project) { create(:project_broken_repo, :public) }

      before do
        sign_in(user)
      end

      User.project_views.keys.each do |project_view|
        context "with #{project_view} view set" do
          before do
            user.update_attributes(project_view: project_view)

            get :show, namespace_id: empty_project.namespace, id: empty_project
          end

          it "renders the empty project view" do
            allow(Project).to receive(:repo).and_raise(Gitlab::Git::Repository::NoRepository)

            expect(response).to render_template('projects/no_repo')
          end
        end
      end
    end

    context "rendering default project view" do
      let(:public_project) { create(:project, :public, :repository) }

      render_views

      it "renders the activity view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('activity')

        get :show, namespace_id: public_project.namespace, id: public_project
        expect(response).to render_template('_activity')
      end

      it "renders the files view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('files')

        get :show, namespace_id: public_project.namespace, id: public_project
        expect(response).to render_template('_files')
      end

      context 'project repo over limit' do
        before do
          allow_any_instance_of(EE::Project)
            .to receive(:above_size_limit?).and_return(true)

          project.team << [user, :master]
        end

        it 'shows the over size limit warning message for project members' do
          allow(controller).to receive(:current_user).and_return(user)

          get :show, namespace_id: public_project.namespace.path, id: public_project.path

          expect(response).to render_template('_above_size_limit_warning')
        end

        it 'does not show the message for non members' do
          get :show, namespace_id: public_project.namespace.path, id: public_project.path

          expect(response).not_to render_template('_above_size_limit_warning')
        end
      end
    end

    context "when the url contains .atom" do
      let(:public_project_with_dot_atom) { build(:empty_project, :public, name: 'my.atom', path: 'my.atom') }

      it 'expects an error creating the project' do
        expect(public_project_with_dot_atom).not_to be_valid
      end
    end

    context 'when the project is pending deletions' do
      it 'renders a 404 error' do
        project = create(:empty_project, pending_delete: true)
        sign_in(user)

        get :show, namespace_id: project.namespace, id: project

        expect(response.status).to eq 404
      end
    end

    context "redirection from http://someproject.git" do
      it 'redirects to project page (format.html)' do
        project = create(:project, :public)

        get :show, namespace_id: project.namespace, id: project, format: :git

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(namespace_project_path)
      end
    end
  end

  describe "#update" do
    render_views

    let(:admin) { create(:admin) }
    let(:project) { create(:project, :repository) }

    before do
      sign_in(admin)
    end

    context 'when only renaming a project path' do
      it "sets the repository to the right path after a rename" do
        expect { update_project path: 'renamed_path' }
          .to change { project.reload.path }

        expect(project.path).to include 'renamed_path'
        expect(assigns(:repository).path).to include project.path
        expect(response).to have_http_status(302)
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

        expect(controller).to set_flash[:alert].to(/container registry tags/)
        expect(response).to have_http_status(200)
      end
    end

    def update_project(**parameters)
      put :update,
          namespace_id: project.namespace.path,
          id: project.path,
          project: parameters
    end
  end

  describe '#transfer' do
    render_views

    let(:project) { create(:project) }
    let(:admin) { create(:admin) }
    let(:new_namespace) { create(:namespace) }

    it 'updates namespace' do
      sign_in(admin)

      put :transfer,
          namespace_id: project.namespace.path,
          new_namespace_id: new_namespace.id,
          id: project.path,
          format: :js

      project.reload

      expect(project.namespace).to eq(new_namespace)
      expect(response).to have_http_status(200)
    end

    context 'when new namespace is empty' do
      it 'project namespace is not changed' do
        controller.instance_variable_set(:@project, project)
        sign_in(admin)

        old_namespace = project.namespace

        put :transfer,
            namespace_id: old_namespace.path,
            new_namespace_id: nil,
            id: project.path,
            format: :js

        project.reload

        expect(project.namespace).to eq(old_namespace)
        expect(response).to have_http_status(200)
        expect(flash[:alert]).to eq 'Please select a new namespace for your project.'
      end
    end
  end

  describe "#destroy" do
    let(:admin) { create(:admin) }

    it "redirects to the dashboard" do
      controller.instance_variable_set(:@project, project)
      sign_in(admin)

      orig_id = project.id
      delete :destroy, namespace_id: project.namespace, id: project

      expect { Project.find(orig_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(dashboard_projects_path)
    end

    context "when the project is forked" do
      let(:project)      { create(:project) }
      let(:fork_project) { create(:project, forked_from_project: project) }
      let(:merge_request) do
        create(:merge_request,
          source_project: fork_project,
          target_project: project)
      end

      it "closes all related merge requests" do
        project.merge_requests << merge_request
        sign_in(admin)

        delete :destroy, namespace_id: fork_project.namespace, id: fork_project

        expect(merge_request.reload.state).to eq('closed')
      end
    end
  end

  describe 'PUT #new_issue_address' do
    subject do
      put :new_issue_address,
        namespace_id: project.namespace,
        id: project
      user.reload
    end

    before do
      sign_in(user)
      project.team << [user, :developer]
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
    end

    it 'has http status 200' do
      expect(response).to have_http_status(200)
    end

    it 'changes the user incoming email token' do
      expect { subject }.to change { user.incoming_email_token }
    end

    it 'changes projects new issue address' do
      expect { subject }.to change { project.new_issue_address(user) }
    end
  end

  describe "POST #toggle_star" do
    it "toggles star if user is signed in" do
      sign_in(user)
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           namespace_id: public_project.namespace,
           id: public_project)
      expect(user.starred?(public_project)).to be_truthy
      post(:toggle_star,
           namespace_id: public_project.namespace,
           id: public_project)
      expect(user.starred?(public_project)).to be_falsey
    end

    it "does nothing if user is not signed in" do
      post(:toggle_star,
           namespace_id: project.namespace,
           id: public_project)
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           namespace_id: project.namespace,
           id: public_project)
      expect(user.starred?(public_project)).to be_falsey
    end
  end

  describe "DELETE remove_fork" do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      context 'with forked project' do
        let(:project_fork) { create(:project, namespace: user.namespace) }

        before do
          create(:forked_project_link, forked_to_project: project_fork)
        end

        it 'removes fork from project' do
          delete(:remove_fork,
              namespace_id: project_fork.namespace.to_param,
              id: project_fork.to_param, format: :js)

          expect(project_fork.forked?).to be_falsey
          expect(flash[:notice]).to eq('The fork relationship has been removed.')
          expect(response).to render_template(:remove_fork)
        end
      end

      context 'when project not forked' do
        let(:unforked_project) { create(:project, namespace: user.namespace) }

        it 'does nothing if project was not forked' do
          delete(:remove_fork,
              namespace_id: unforked_project.namespace,
              id: unforked_project, format: :js)

          expect(flash[:notice]).to be_nil
          expect(response).to render_template(:remove_fork)
        end
      end
    end

    it "does nothing if user is not signed in" do
      delete(:remove_fork,
          namespace_id: project.namespace,
          id: project, format: :js)
      expect(response).to have_http_status(401)
    end
  end

  describe "GET refs" do
    let(:public_project) { create(:project, :public) }

    it "gets a list of branches and tags" do
      get :refs, namespace_id: public_project.namespace, id: public_project

      parsed_body = JSON.parse(response.body)
      expect(parsed_body["Branches"]).to include("master")
      expect(parsed_body["Tags"]).to include("v1.0.0")
      expect(parsed_body["Commits"]).to be_nil
    end

    it "gets a list of branches, tags and commits" do
      get :refs, namespace_id: public_project.namespace, id: public_project, ref: "123456"

      parsed_body = JSON.parse(response.body)
      expect(parsed_body["Branches"]).to include("master")
      expect(parsed_body["Tags"]).to include("v1.0.0")
      expect(parsed_body["Commits"]).to include("123456")
    end
  end

  describe 'GET edit' do
    it 'does not allow an auditor user to access the page' do
      sign_in(create(:user, :auditor))

      get :edit,
          namespace_id: project.namespace.path,
          id: project.path

      expect(response).to have_http_status(404)
    end

    it 'allows an admin user to access the page' do
      sign_in(create(:user, :admin))

      get :edit,
          namespace_id: project.namespace.path,
          id: project.path

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      sign_in(user)

      post :preview_markdown, namespace_id: public_project.namespace, id: public_project, text: '*Markdown* text'

      expect(JSON.parse(response.body).keys).to match_array(%w(body references))
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
            get :show, namespace_id: public_project.namespace, id: public_project

            expect(assigns(:project)).to eq(public_project)
            expect(response).to have_http_status(200)
          end
        end

        context "with different casing" do
          it "redirects to the normalized path" do
            get :show, namespace_id: public_project.namespace, id: public_project.path.upcase

            expect(assigns(:project)).to eq(public_project)
            expect(response).to redirect_to("/#{public_project.full_path}")
            expect(controller).not_to set_flash[:notice]
          end
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { public_project.redirect_routes.create!(path: "foo/bar") }

        it 'redirects to the canonical path' do
          get :show, namespace_id: 'foo', id: 'bar'

          expect(response).to redirect_to(public_project)
          expect(controller).to set_flash[:notice].to(project_moved_message(redirect_route, public_project))
        end

        it 'redirects to the canonical path (testing non-show action)' do
          get :refs, namespace_id: 'foo', id: 'bar'

          expect(response).to redirect_to(refs_project_path(public_project))
          expect(controller).to set_flash[:notice].to(project_moved_message(redirect_route, public_project))
        end
      end
    end

    context 'for a POST request' do
      context 'when requesting the canonical path with different casing' do
        it 'does not 404' do
          post :toggle_star, namespace_id: public_project.namespace, id: public_project.path.upcase

          expect(response).not_to have_http_status(404)
        end

        it 'does not redirect to the correct casing' do
          post :toggle_star, namespace_id: public_project.namespace, id: public_project.path.upcase

          expect(response).not_to have_http_status(301)
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { public_project.redirect_routes.create!(path: "foo/bar") }

        it 'returns not found' do
          post :toggle_star, namespace_id: 'foo', id: 'bar'

          expect(response).to have_http_status(404)
        end
      end
    end

    context 'for a DELETE request' do
      before do
        sign_in(create(:admin))
      end

      context 'when requesting the canonical path with different casing' do
        it 'does not 404' do
          delete :destroy, namespace_id: project.namespace, id: project.path.upcase

          expect(response).not_to have_http_status(404)
        end

        it 'does not redirect to the correct casing' do
          delete :destroy, namespace_id: project.namespace, id: project.path.upcase

          expect(response).not_to have_http_status(301)
        end
      end

      context 'when requesting a redirected path' do
        let!(:redirect_route) { project.redirect_routes.create!(path: "foo/bar") }

        it 'returns not found' do
          delete :destroy, namespace_id: 'foo', id: 'bar'

          expect(response).to have_http_status(404)
        end
      end
    end
  end

  def project_moved_message(redirect_route, project)
    "Project '#{redirect_route.path}' was moved to '#{project.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
