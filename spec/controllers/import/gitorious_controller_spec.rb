require 'spec_helper'

describe Import::GitoriousController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "GET new" do
    it "redirects to import endpoint on gitorious.org" do
      get :new

      expect(controller).to redirect_to("https://gitorious.org/gitlab-import?callback_url=http://test.host/import/gitorious/callback")
    end
  end

  describe "GET callback" do
    it "stores repo list in session" do
      get :callback, repos: 'foo/bar,baz/qux'

      expect(session[:gitorious_repos]).to eq('foo/bar,baz/qux')
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(full_name: 'asd/vim')
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'gitorious', creator_id: user.id)
      controller.stub_chain(:client, :repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'gitorious', creator_id: user.id, import_source: 'asd/vim')
      controller.stub_chain(:client, :repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe "POST create" do
    before do
      @repo = Gitlab::GitoriousImport::Repository.new('asd/vim')
    end

    it "takes already existing namespace" do
      namespace = create(:namespace, name: "asd", owner: user)
      expect(Gitlab::GitoriousImport::ProjectCreator).
        to receive(:new).with(@repo, namespace, user).
        and_return(double(execute: true))
      controller.stub_chain(:client, :repo).and_return(@repo)

      post :create, format: :js
    end
  end
end
