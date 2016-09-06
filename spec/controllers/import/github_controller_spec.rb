require 'spec_helper'

describe Import::GithubController do
  include ImportSpecHelper

  let(:user) { create(:user) }
  let(:token) { "asdasd12345" }
  let(:access_params) { { github_access_token: token } }

  def assign_session_token
    session[:github_access_token] = token
  end

  before do
    sign_in(user)
    allow(controller).to receive(:github_import_enabled?).and_return(true)
  end

  describe "GET new" do
    it "redirects to GitHub for an access token if logged in with GitHub" do
      allow(controller).to receive(:logged_in_with_github?).and_return(true)
      expect(controller).to receive(:go_to_github_for_permissions)

      get :new
    end

    it "redirects to status if we already have a token" do
      assign_session_token
      allow(controller).to receive(:logged_in_with_github?).and_return(false)

      get :new

      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "GET callback" do
    it "updates access token" do
      token = "asdasd12345"
      allow_any_instance_of(Gitlab::GithubImport::Client).
        to receive(:get_token).and_return(token)
      allow_any_instance_of(Gitlab::GithubImport::Client).
        to receive(:github_options).and_return({})
      stub_omniauth_provider('github')

      get :callback

      expect(session[:github_access_token]).to eq(token)
      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "POST personal_access_token" do
    it "updates access token" do
      token = "asdfasdf9876"

      allow_any_instance_of(Gitlab::GithubImport::Client).
        to receive(:user).and_return(true)

      post :personal_access_token, personal_access_token: token

      expect(session[:github_access_token]).to eq(token)
      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(login: 'vim', full_name: 'asd/vim')
      @org = OpenStruct.new(login: 'company')
      @org_repo = OpenStruct.new(login: 'company', full_name: 'company/repo')
      assign_session_token
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'github', creator_id: user.id)
      stub_client(repos: [@repo, @org_repo], orgs: [@org], org_repos: [@org_repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo, @org_repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'github', creator_id: user.id, import_source: 'asd/vim')
      stub_client(repos: [@repo], orgs: [])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end

    it "handles an invalid access token" do
      allow_any_instance_of(Gitlab::GithubImport::Client).
        to receive(:repos).and_raise(Octokit::Unauthorized)

      get :status

      expect(session[:github_access_token]).to eq(nil)
      expect(controller).to redirect_to(new_import_github_url)
      expect(flash[:alert]).to eq('Access denied to your GitHub account.')
    end
  end

  describe "POST create" do
    let(:github_username) { user.username }
    let(:github_user) { OpenStruct.new(login: github_username) }
    let(:github_repo) do
      OpenStruct.new(
        name: 'vim',
        full_name: "#{github_username}/vim",
        owner: OpenStruct.new(login: github_username)
      )
    end

    before do
      stub_client(user: github_user, repo: github_repo)
      assign_session_token
    end

    context "when the repository owner is the GitHub user" do
      context "when the GitHub user and GitLab user's usernames match" do
        it "takes the current user's namespace" do
          expect(Gitlab::GithubImport::ProjectCreator).
            to receive(:new).with(github_repo, user.namespace, user, access_params).
            and_return(double(execute: true))

          post :create, format: :js
        end
      end

      context "when the GitHub user and GitLab user's usernames don't match" do
        let(:github_username) { "someone_else" }

        it "takes the current user's namespace" do
          expect(Gitlab::GithubImport::ProjectCreator).
            to receive(:new).with(github_repo, user.namespace, user, access_params).
            and_return(double(execute: true))

          post :create, format: :js
        end
      end
    end

    context "when the repository owner is not the GitHub user" do
      let(:other_username) { "someone_else" }

      before do
        github_repo.owner = OpenStruct.new(login: other_username)
        assign_session_token
      end

      context "when a namespace with the GitHub user's username already exists" do
        let!(:existing_namespace) { create(:namespace, name: other_username, owner: user) }

        context "when the namespace is owned by the GitLab user" do
          it "takes the existing namespace" do
            expect(Gitlab::GithubImport::ProjectCreator).
              to receive(:new).with(github_repo, existing_namespace, user, access_params).
              and_return(double(execute: true))

            post :create, format: :js
          end
        end

        context "when the namespace is not owned by the GitLab user" do
          before do
            existing_namespace.owner = create(:user)
            existing_namespace.save
          end

          it "doesn't create a project" do
            expect(Gitlab::GithubImport::ProjectCreator).
              not_to receive(:new)

            post :create, format: :js
          end
        end
      end

      context "when a namespace with the GitHub user's username doesn't exist" do
        context "when current user can create namespaces" do
          it "creates the namespace" do
            expect(Gitlab::GithubImport::ProjectCreator).
              to receive(:new).and_return(double(execute: true))

            expect { post :create, format: :js }.to change(Namespace, :count).by(1)
          end

          it "takes the new namespace" do
            expect(Gitlab::GithubImport::ProjectCreator).
              to receive(:new).with(github_repo, an_instance_of(Group), user, access_params).
              and_return(double(execute: true))

            post :create, format: :js
          end
        end

        context "when current user can't create namespaces" do
          before do
            user.update_attribute(:can_create_group, false)
          end

          it "doesn't create the namespace" do
            expect(Gitlab::GithubImport::ProjectCreator).
              to receive(:new).and_return(double(execute: true))

            expect { post :create, format: :js }.not_to change(Namespace, :count)
          end

          it "takes the current user's namespace" do
            expect(Gitlab::GithubImport::ProjectCreator).
              to receive(:new).with(github_repo, user.namespace, user, access_params).
              and_return(double(execute: true))

            post :create, format: :js
          end
        end
      end
    end
  end
end
