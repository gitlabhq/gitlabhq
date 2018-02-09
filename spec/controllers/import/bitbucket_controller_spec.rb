require 'spec_helper'

describe Import::BitbucketController do
  include ImportSpecHelper

  let(:user) { create(:user) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:refresh_token) { SecureRandom.hex(15) }
  let(:access_params) { { token: token, expires_at: nil, expires_in: nil, refresh_token: nil } }

  def assign_session_tokens
    session[:bitbucket_token] = token
  end

  before do
    sign_in(user)
    allow(controller).to receive(:bitbucket_import_enabled?).and_return(true)
  end

  describe "GET callback" do
    before do
      session[:oauth_request_token] = {}
    end

    it "updates access token" do
      expires_at = Time.now + 1.day
      expires_in = 1.day
      access_token = double(token: token,
                            secret: secret,
                            expires_at: expires_at,
                            expires_in: expires_in,
                            refresh_token: refresh_token)
      allow_any_instance_of(OAuth2::Client)
        .to receive(:get_token).and_return(access_token)
      stub_omniauth_provider('bitbucket')

      get :callback

      expect(session[:bitbucket_token]).to eq(token)
      expect(session[:bitbucket_refresh_token]).to eq(refresh_token)
      expect(session[:bitbucket_expires_at]).to eq(expires_at)
      expect(session[:bitbucket_expires_in]).to eq(expires_in)
      expect(controller).to redirect_to(status_import_bitbucket_url)
    end
  end

  describe "GET status" do
    before do
      @repo = double(slug: 'vim', owner: 'asd', full_name: 'asd/vim', "valid?" => true)
      assign_session_tokens
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'bitbucket', creator_id: user.id)
      allow_any_instance_of(Bitbucket::Client).to receive(:repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
      expect(assigns(:incompatible_repos)).to eq([])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'bitbucket', creator_id: user.id, import_source: 'asd/vim')
      allow_any_instance_of(Bitbucket::Client).to receive(:repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe "POST create" do
    let(:bitbucket_username) { user.username }

    let(:bitbucket_user) do
      double(username: bitbucket_username)
    end

    let(:bitbucket_repo) do
      double(slug: "vim", owner: bitbucket_username, name: 'vim')
    end

    before do
      allow_any_instance_of(Bitbucket::Client).to receive(:repo).and_return(bitbucket_repo)
      allow_any_instance_of(Bitbucket::Client).to receive(:user).and_return(bitbucket_user)
      assign_session_tokens
    end

    context "when the repository owner is the Bitbucket user" do
      context "when the Bitbucket user and GitLab user's usernames match" do
        it "takes the current user's namespace" do
          expect(Gitlab::BitbucketImport::ProjectCreator)
            .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
            .and_return(double(execute: true))

          post :create, format: :js
        end
      end

      context "when the Bitbucket user and GitLab user's usernames don't match" do
        let(:bitbucket_username) { "someone_else" }

        it "takes the current user's namespace" do
          expect(Gitlab::BitbucketImport::ProjectCreator)
            .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
            .and_return(double(execute: true))

          post :create, format: :js
        end
      end

      context 'when the Bitbucket user is unauthorized' do
        render_views

        it 'returns unauthorized' do
          allow(controller).to receive(:current_user).and_return(user)
          allow(user).to receive(:can?).and_return(false)

          post :create, format: :js
        end
      end
    end

    context "when the repository owner is not the Bitbucket user" do
      let(:other_username) { "someone_else" }

      before do
        allow(bitbucket_repo).to receive(:owner).and_return(other_username)
      end

      context "when a namespace with the Bitbucket user's username already exists" do
        let!(:existing_namespace) { create(:group, name: other_username) }

        context "when the namespace is owned by the GitLab user" do
          before do
            existing_namespace.add_owner(user)
          end

          it "takes the existing namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, existing_namespace, user, access_params)
              .and_return(double(execute: true))

            post :create, format: :js
          end
        end

        context "when the namespace is not owned by the GitLab user" do
          it "doesn't create a project" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .not_to receive(:new)

            post :create, format: :js
          end
        end
      end

      context "when a namespace with the Bitbucket user's username doesn't exist" do
        context "when current user can create namespaces" do
          it "creates the namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).and_return(double(execute: true))

            expect { post :create, format: :js }.to change(Namespace, :count).by(1)
          end

          it "takes the new namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, an_instance_of(Group), user, access_params)
              .and_return(double(execute: true))

            post :create, format: :js
          end
        end

        context "when current user can't create namespaces" do
          before do
            user.update_attribute(:can_create_group, false)
          end

          it "doesn't create the namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).and_return(double(execute: true))

            expect { post :create, format: :js }.not_to change(Namespace, :count)
          end

          it "takes the current user's namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
              .and_return(double(execute: true))

            post :create, format: :js
          end
        end
      end
    end

    context 'user has chosen an existing nested namespace and name for the project', :postgresql do
      let(:parent_namespace) { create(:group, name: 'foo', owner: user) }
      let(:nested_namespace) { create(:group, name: 'bar', parent: parent_namespace) }
      let(:test_name) { 'test_name' }

      before do
        nested_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, nested_namespace, user, access_params)
            .and_return(double(execute: true))

        post :create, { target_namespace: nested_namespace.full_path, new_name: test_name, format: :js }
      end
    end

    context 'user has chosen a non-existent nested namespaces and name for the project', :postgresql do
      let(:test_name) { 'test_name' }

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js }
      end

      it 'creates the namespaces' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: true))

        expect { post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js } }
          .to change { Namespace.count }.by(2)
      end

      it 'new namespace has the right parent' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js }

        expect(Namespace.find_by_path_or_name('bar').parent.path).to eq('foo')
      end
    end

    context 'user has chosen existent and non-existent nested namespaces and name for the project', :postgresql do
      let(:test_name) { 'test_name' }
      let!(:parent_namespace) { create(:group, name: 'foo', owner: user) }

      before do
        parent_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js }
      end

      it 'creates the namespaces' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: true))

        expect { post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js } }
          .to change { Namespace.count }.by(2)
      end
    end
  end
end
