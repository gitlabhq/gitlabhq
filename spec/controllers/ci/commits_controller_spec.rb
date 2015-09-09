require "spec_helper"

describe Ci::CommitsController do
  before do
    @project = FactoryGirl.create :ci_project
  end

  describe "GET /status" do
    it "returns status of commit" do
      commit = FactoryGirl.create :ci_commit, project: @project
      get :status, id: commit.sha, ref_id: commit.ref, project_id: @project.id

      expect(response).to be_success
      expect(response.code).to eq('200')
      JSON.parse(response.body)["status"] == "pending"
    end

    it "returns not_found status" do
      commit = FactoryGirl.create :ci_commit, project: @project
      get :status, id: commit.sha, ref_id: "deploy", project_id: @project.id

      expect(response).to be_success
      expect(response.code).to eq('200')
      JSON.parse(response.body)["status"] == "not_found"
    end
  end
end
