require 'spec_helper'

describe GithubImportsController do
  let(:user) { create(:user, github_access_token: 'asd123') }

  before do
    sign_in(user)
  end

  describe "GET callback" do
    it "updates access token" do
      token = "asdasd12345"
      Gitlab::Github::Client.any_instance.stub_chain(:client, :auth_code, :get_token, :token).and_return(token)

      get :callback
      
      user.reload.github_access_token.should == token
      controller.should redirect_to(status_github_import_url)
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(login: 'vim', full_name: 'asd/vim')
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'github', creator_id: user.id)
      controller.stub_chain(:octo_client, :repos).and_return([@repo])
      controller.stub_chain(:octo_client, :orgs).and_return([])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'github', creator_id: user.id, import_source: 'asd/vim')
      controller.stub_chain(:octo_client, :repos).and_return([@repo])
      controller.stub_chain(:octo_client, :orgs).and_return([])

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
      Gitlab::Github::ProjectCreator.should_receive(:new).with(@repo, namespace, user).
        and_return(double(execute: true))
      controller.stub_chain(:octo_client, :repo).and_return(@repo)

      post :create, format: :js
    end
  end
end
