require 'spec_helper'

describe Import::GithubController do
  let(:user) { create(:user, github_access_token: 'asd123') }

  before do
    sign_in(user)
    controller.stub(:github_import_enabled?).and_return(true)
  end

  describe "GET callback" do
    it "updates access token" do
      token = "asdasd12345"
      allow_any_instance_of(Gitlab::GithubImport::Client).
        to receive(:get_token).and_return(token)
      Gitlab.config.omniauth.providers << OpenStruct.new(app_id: 'asd123',
                                                         app_secret: 'asd123',
                                                         name: 'github')

      get :callback

      expect(user.reload.github_access_token).to eq(token)
      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(login: 'vim', full_name: 'asd/vim')
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'github', creator_id: user.id)
      controller.stub_chain(:client, :repos).and_return([@repo])
      controller.stub_chain(:client, :orgs).and_return([])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'github', creator_id: user.id, import_source: 'asd/vim')
      controller.stub_chain(:client, :repos).and_return([@repo])
      controller.stub_chain(:client, :orgs).and_return([])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe "POST create" do
    before do
      @repo = OpenStruct.new(login: 'vim', full_name: 'asd/vim', owner: OpenStruct.new(login: "john"))
    end

    it "takes already existing namespace" do
      namespace = create(:namespace, name: "john", owner: user)
      expect(Gitlab::GithubImport::ProjectCreator).
        to receive(:new).with(@repo, namespace, user).
        and_return(double(execute: true))
      controller.stub_chain(:client, :repo).and_return(@repo)

      post :create, format: :js
    end
  end
end
