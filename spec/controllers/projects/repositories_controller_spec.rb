require "spec_helper"

describe Projects::RepositoriesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  describe "GET archive" do
    before do
      sign_in(user)
      project.team << [user, :developer]

      allow(ArchiveRepositoryService).to receive(:new).and_return(service)
    end

    let(:service) { ArchiveRepositoryService.new(project, "master", "zip") }

    it "executes ArchiveRepositoryService" do
      expect(ArchiveRepositoryService).to receive(:new).with(project, "master", "zip")
      expect(service).to receive(:execute)

      get :archive, namespace_id: project.namespace.path, project_id: project.path, ref: "master", format: "zip"
    end

    context "when the service raises an error" do

      before do
        allow(service).to receive(:execute).and_raise("Archive failed")
      end

      it "renders Not Found" do
        get :archive, namespace_id: project.namespace.path, project_id: project.path, ref: "master", format: "zip"

        expect(response.status).to eq(404)
      end
    end
  end
end
