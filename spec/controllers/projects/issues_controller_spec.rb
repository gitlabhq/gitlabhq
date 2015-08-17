require('spec_helper')

describe Projects::IssuesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
    project.team << [user, :developer]
    controller.instance_variable_set(:@project, project)
  end

  describe "GET #index" do
    it "returns index" do
      get :index, namespace_id: project.namespace.id, project_id: project.id

      expect(response.status).to eq(200)
    end

    it "returns 404 when issues are disabled" do
      project.issues_enabled = false
      project.save

      get :index, namespace_id: project.namespace.id, project_id: project.id
      expect(response.status).to eq(404)
    end

    it "returns 404 when external issue tracker is enabled" do
      allow(project).to receive(:default_issues_tracker?).and_return(false)

      get :index, namespace_id: project.namespace.id, project_id: project.id
      expect(response.status).to eq(404)
    end

  end
end
