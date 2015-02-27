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
    before do
      @repo = {
        path: 'vim',
        path_with_namespace: 'asd/vim',
        owner: {name: "john"},
        namespace: {path: "john"}
      }.with_indifferent_access
    end

    it "takes already existing namespace" do
      namespace = create(:namespace, name: "john", owner: user)
      expect(Gitlab::GitlabImport::ProjectCreator).
        to receive(:new).with(@repo, namespace, user).
        and_return(double(execute: true))
      controller.stub_chain(:client, :project).and_return(@repo)

      post :create, format: :js
    end
  end
end
