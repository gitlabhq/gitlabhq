require 'spec_helper'

describe Import::BitbucketController do
  let(:user) { create(:user, bitbucket_access_token: 'asd123', bitbucket_access_token_secret: "sekret") }

  before do
    sign_in(user)
    controller.stub(:bitbucket_import_enabled?).and_return(true)
  end

  describe "GET callback" do
    before do
      session[:oauth_request_token] = {}
    end
    
    it "updates access token" do
      token = "asdasd12345"
      secret = "sekrettt"
      access_token = double(token: token, secret: secret)
      Gitlab::BitbucketImport::Client.any_instance.stub(:get_token).and_return(access_token)
      Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "bitbucket")

      get :callback

      expect(user.reload.bitbucket_access_token).to eq(token)
      expect(user.reload.bitbucket_access_token_secret).to eq(secret)
      expect(controller).to redirect_to(status_import_bitbucket_url)
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(slug: 'vim', owner: 'asd')
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'bitbucket', creator_id: user.id)
      controller.stub_chain(:client, :projects).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'bitbucket', creator_id: user.id, import_source: 'asd/vim')
      controller.stub_chain(:client, :projects).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe "POST create" do
    before do
      @repo = {
        slug: 'vim',
        owner: "john"
      }.with_indifferent_access
    end

    it "takes already existing namespace" do
      namespace = create(:namespace, name: "john", owner: user)
      expect(Gitlab::BitbucketImport::KeyAdder).
        to receive(:new).with(@repo, user).
        and_return(double(execute: true))
      expect(Gitlab::BitbucketImport::ProjectCreator).
        to receive(:new).with(@repo, namespace, user).
        and_return(double(execute: true))
      controller.stub_chain(:client, :project).and_return(@repo)

      post :create, format: :js
    end
  end
end
