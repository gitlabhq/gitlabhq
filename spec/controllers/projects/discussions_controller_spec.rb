require 'spec_helper'

describe Projects::DiscussionsController do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

  describe 'POST resolve' do
    before do
      sign_in user
    end

    context "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

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
          post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

          expect(response).to have_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "resolves the discussion" do
          expect_any_instance_of(Discussion).to receive(:resolve!).with(user)

          post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id
        end

        it "checks whether all notes are resolved" do
          expect_any_instance_of(MergeRequests::AllDiscussionsResolvedService).to receive(:execute).with(merge_request)

          post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id
        end

        it "returns the name of the resolving user" do
          post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

          expect(JSON.parse(response.body)["resolved_by"]).to eq(user.name)
        end

        it "returns status 200" do
          post :resolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

          expect(response).to have_http_status(200)
        end
      end
    end
  end

  describe 'DELETE unresolve' do
    before do
      sign_in user
    end

    context "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        delete :unresolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

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
          delete :unresolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

          expect(response).to have_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "unresolves the discussion" do
          expect_any_instance_of(Discussion).to receive(:unresolve!)

          delete :unresolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id
        end

        it "returns status 200" do
          delete :unresolve, namespace_id: project.namespace.path, project_id: project.path, merge_request_id: merge_request.iid, id: note.discussion_id

          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
