require "spec_helper"

describe Ci::CommitsController do
  describe "GET /status" do
    it "returns status of commit" do
      commit = FactoryGirl.create :ci_commit
      get :status, id: commit.sha, ref_id: commit.ref, project_id: commit.project.id

      expect(response).to be_success
      expect(response.code).to eq('200')
      JSON.parse(response.body)["status"] == "pending"
    end

    it "returns not_found status" do
      commit = FactoryGirl.create :ci_commit
      get :status, id: commit.sha, ref_id: "deploy", project_id: commit.project.id

      expect(response).to be_success
      expect(response.code).to eq('200')
      JSON.parse(response.body)["status"] == "not_found"
    end
  end
end
