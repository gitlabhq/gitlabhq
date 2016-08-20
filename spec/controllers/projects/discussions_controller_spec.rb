require 'spec_helper'

describe Projects::DiscussionsController do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
  let(:discussion) { note.discussion }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      merge_request_id: merge_request,
      id: note.discussion_id
    }
  end

  describe 'POST resolve' do
    before do
      sign_in user
    end

    xcontext "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        post :resolve, request_params

        expect(response).to have_http_status(404)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before do
        project.team << [user, :developer]
      end

      context "when the discussion is not resolvable" do
        before do
          note.update(system: true)
        end

        it "returns status 404" do
          post :resolve, request_params

          expect(response).to have_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "resolves the discussion" do
          post :resolve, request_params

          expect(note.reload.discussion.resolved?).to be true
          expect(note.reload.discussion.resolved_by).to eq(user)
        end

        it "sends notifications if all discussions are resolved" do
          expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

          post :resolve, request_params
        end

        it "returns the name of the resolving user" do
          post :resolve, request_params

          expect(JSON.parse(response.body)["resolved_by"]).to eq(user.name)
        end

        it "returns status 200" do
          post :resolve, request_params

          expect(response).to have_http_status(200)
        end
      end
    end
  end

  describe 'DELETE unresolve' do
    before do
      sign_in user

      note.discussion.resolve!(user)
    end

    context "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        delete :unresolve, request_params

        expect(response).to have_http_status(404)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before do
        project.team << [user, :developer]
      end

      context "when the discussion is not resolvable" do
        before do
          note.update(system: true)
        end

        it "returns status 404" do
          delete :unresolve, request_params

          expect(response).to have_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "unresolves the discussion" do
          delete :unresolve, request_params

          expect(note.reload.discussion.resolved?).to be false
        end

        it "returns status 200" do
          delete :unresolve, request_params

          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
