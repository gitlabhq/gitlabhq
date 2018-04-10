require "spec_helper"

describe Projects::RepositoriesController do
  let(:project) { create(:project, :repository) }

  describe "GET archive" do
    context 'as a guest' do
      it 'responds with redirect in correct format' do
        get :archive, namespace_id: project.namespace, project_id: project, id: "master", format: "zip"

        expect(response.header["Content-Type"]).to start_with('text/html')
        expect(response).to be_redirect
      end
    end

    context 'as a user' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
        sign_in(user)
      end

      it "uses Gitlab::Workhorse" do
        get :archive, namespace_id: project.namespace, project_id: project, id: "master", format: "zip"

        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      it 'responds with redirect to the short name archive if fully qualified' do
        get :archive, namespace_id: project.namespace, project_id: project, id: "master/#{project.path}-master", format: "zip"

        expect(assigns(:ref)).to eq("master")
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      it 'handles legacy queries with no ref' do
        get :archive, namespace_id: project.namespace, project_id: project, format: "zip"

        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      context "when the service raises an error" do
        before do
          allow(Gitlab::Workhorse).to receive(:send_git_archive).and_raise("Archive failed")
        end

        it "renders Not Found" do
          get :archive, namespace_id: project.namespace, project_id: project, id: "master", format: "zip"

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
