require "spec_helper"

describe Projects::RepositoriesController do
  let(:project) { create(:project) }

  describe "GET archive" do
    context 'as a guest' do
      it 'responds with redirect in correct format' do
        get :archive, namespace_id: project.namespace.path, project_id: project.path, format: "zip"

        expect(response.content_type).to start_with 'text/html'
        expect(response).to be_redirect
      end
    end

    context 'as a user' do
      let(:user) { create(:user) }

      before do
        project.team << [user, :developer]
        sign_in(user)
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
end
