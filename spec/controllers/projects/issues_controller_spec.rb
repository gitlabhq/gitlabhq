require('spec_helper')

describe Projects::IssuesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
    project.team << [user, :developer]
  end

  describe "GET #index" do
    it "returns index" do
      get :index, namespace_id: project.namespace.path, project_id: project.path

      expect(response.status).to eq(200)
    end

    it "return 301 if request path doesn't match project path" do
      get :index, namespace_id: project.namespace.path, project_id: project.path.upcase

      expect(response).to redirect_to(namespace_project_issues_path(project.namespace, project))
    end

    it "returns 404 when issues are disabled" do
      project.issues_enabled = false
      project.save

      get :index, namespace_id: project.namespace.path, project_id: project.path
      expect(response.status).to eq(404)
    end

    it "returns 404 when external issue tracker is enabled" do
      controller.instance_variable_set(:@project, project)
      allow(project).to receive(:default_issues_tracker?).and_return(false)

      get :index, namespace_id: project.namespace.path, project_id: project.path
      expect(response.status).to eq(404)
    end

  end
end
