require 'spec_helper'

describe Projects::DiscussionsController do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.source_project }
  let(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
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

    context "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        post :resolve, request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before do
        project.add_developer(user)
      end

      context "when the discussion is not resolvable" do
        before do
          note.update(system: true)
        end

        it "returns status 404" do
          post :resolve, request_params

          expect(response).to have_gitlab_http_status(404)
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

          expect(response).to have_gitlab_http_status(200)
        end

        context "when vue_mr_discussions cookie is present" do
          before do
            allow(controller).to receive(:cookies).and_return(vue_mr_discussions: 'true')
          end

          it "renders discussion with serializer" do
            expect_any_instance_of(DiscussionSerializer).to receive(:represent)
              .with(instance_of(Discussion), { context: instance_of(described_class) })

            post :resolve, request_params
          end
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

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before do
        project.add_developer(user)
      end

      context "when the discussion is not resolvable" do
        before do
          note.update(system: true)
        end

        it "returns status 404" do
          delete :unresolve, request_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "unresolves the discussion" do
          delete :unresolve, request_params

          expect(note.reload.discussion.resolved?).to be false
        end

        it "returns status 200" do
          delete :unresolve, request_params

          expect(response).to have_gitlab_http_status(200)
        end

        context "when vue_mr_discussions cookie is present" do
          before do
            allow(controller).to receive(:cookies).and_return({ vue_mr_discussions: 'true' })
          end

          it "renders discussion with serializer" do
            expect_any_instance_of(DiscussionSerializer).to receive(:represent)
              .with(instance_of(Discussion), { context: instance_of(described_class) })

            delete :unresolve, request_params
          end
        end
      end
    end
  end
end
