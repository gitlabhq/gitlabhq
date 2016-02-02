require "spec_helper"

describe Projects::RepositoriesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  describe "GET archive" do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    it "uses Gitlab::Workhorse" do
      expect(Gitlab::Workhorse).to receive(:send_git_archive).with(project, "master", "zip")

      get :archive, namespace_id: project.namespace.path, project_id: project.path, ref: "master", format: "zip"
    end

    context "when the service raises an error" do

      before do
        allow(Gitlab::Workhorse).to receive(:send_git_archive).and_raise("Archive failed")
      end

      it "renders Not Found" do
        get :archive, namespace_id: project.namespace.path, project_id: project.path, ref: "master", format: "zip"

        expect(response.status).to eq(404)
      end
    end
  end
end
