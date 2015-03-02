require('spec_helper')

describe Projects::ProtectedBranchesController do
  describe "GET #index" do
    let(:project) { create(:project_empty_repo, :public) }
    it "redirect empty repo to projects page" do
      get(:index, namespace_id: project.namespace.to_param, project_id: project.to_param)
    end
  end
end
