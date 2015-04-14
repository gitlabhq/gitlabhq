require 'spec_helper'

describe Import::GitlabController do
  let(:user) { create(:user, gitlab_access_token: 'asd123') }

  before do
    sign_in(user)
    controller.stub(:gitlab_import_enabled?).and_return(true)
  end

  describe "GET callback" do
    it "updates access token" do
      token = "asdasd12345"
      Gitlab::GitlabImport::Client.any_instance.stub_chain(:client, :auth_code, :get_token, :token).and_return(token)
      Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "gitlab")

      get :callback

      expect(user.reload.gitlab_access_token).to eq(token)
      expect(controller).to redirect_to(status_import_gitlab_url)
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(path: 'vim', path_with_namespace: 'asd/vim')
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'gitlab', creator_id: user.id)
      controller.stub_chain(:client, :projects).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'gitlab', creator_id: user.id, import_source: 'asd/vim')
      controller.stub_chain(:client, :projects).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe "POST create" do
    let(:gitlab_username) { user.username }

    let(:gitlab_user) {
      {
        username: gitlab_username
      }.with_indifferent_access
    }

    let(:gitlab_repo) {
      {
        path: 'vim',
        path_with_namespace: "#{gitlab_username}/vim",
        owner: { name: gitlab_username },
        namespace: { path: gitlab_username }
      }.with_indifferent_access
    }

    before do
      controller.stub_chain(:client, :user).and_return(gitlab_user)
      controller.stub_chain(:client, :project).and_return(gitlab_repo)
    end

    context "when the repository owner is the GitLab.com user" do
      context "when the GitLab.com user and GitLab server user's usernames match" do
        it "takes the current user's namespace" do
          expect(Gitlab::GitlabImport::ProjectCreator).
            to receive(:new).with(gitlab_repo, user.namespace, user).
            and_return(double(execute: true))

          post :create, format: :js
        end
      end

      context "when the GitLab.com user and GitLab server user's usernames don't match" do
        let(:gitlab_username) { "someone_else" }

        it "takes the current user's namespace" do
          expect(Gitlab::GitlabImport::ProjectCreator).
            to receive(:new).with(gitlab_repo, user.namespace, user).
            and_return(double(execute: true))

          post :create, format: :js
        end
      end
    end

    context "when the repository owner is not the GitLab.com user" do
      let(:other_username) { "someone_else" }

      before do
        gitlab_repo["namespace"]["path"] = other_username
      end

      context "when a namespace with the GitLab.com user's username already exists" do
        let!(:existing_namespace) { create(:namespace, name: other_username, owner: user) }

        context "when the namespace is owned by the GitLab server user" do
          it "takes the existing namespace" do
            expect(Gitlab::GitlabImport::ProjectCreator).
              to receive(:new).with(gitlab_repo, existing_namespace, user).
              and_return(double(execute: true))

            post :create, format: :js
          end
        end

        context "when the namespace is not owned by the GitLab server user" do
          before do
            existing_namespace.owner = create(:user)
            existing_namespace.save
          end

          it "doesn't create a project" do
            expect(Gitlab::GitlabImport::ProjectCreator).
              not_to receive(:new)

            post :create, format: :js
          end
        end
      end

      context "when a namespace with the GitLab.com user's username doesn't exist" do
        it "creates the namespace" do
          expect(Gitlab::GitlabImport::ProjectCreator).
            to receive(:new).and_return(double(execute: true))

          post :create, format: :js

          expect(Namespace.where(name: other_username).first).not_to be_nil
        end

        it "takes the new namespace" do
          expect(Gitlab::GitlabImport::ProjectCreator).
            to receive(:new).with(gitlab_repo, an_instance_of(Group), user).
            and_return(double(execute: true))

          post :create, format: :js
        end
      end
    end
  end
end
