require "spec_helper"

describe Ci::ProjectsController do
  before do
    @project = FactoryGirl.create :ci_project
  end

  describe "POST /projects" do
    let(:project_dump) { OpenStruct.new({ id: @project.gitlab_id }) }

    let(:user) do
      create(:user)
    end

    before do
      sign_in(user)
    end

    it "creates project" do
      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(assigns(:project)).not_to be_a_new(Ci::Project)
    end

    it "shows error" do
      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(flash[:alert]).to include("You have to have at least master role to enable CI for this project")
    end
  end

  describe "GET /gitlab" do
    let(:user) do
      create(:user)
    end

    before do
      sign_in(user)
    end

    it "searches projects" do
      xhr :get, :index, { search: "str", format: "json" }.with_indifferent_access

      expect(response).to be_success
      expect(response.code).to eq('200')
    end
  end
end
