# frozen_string_literal: true

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

  describe 'GET show' do
    before do
      sign_in user
    end

    context 'when user is not authorized to read the MR' do
      it 'returns 404' do
        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user is authorized to read the MR' do
      before do
        project.add_reporter(user)
      end

      it 'returns status 200' do
        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns status 404 if MR does not exists' do
        merge_request.destroy!

        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user is authorized but note is LegacyDiffNote' do
      before do
        project.add_developer(user)
        note.update!(type: 'LegacyDiffNote')
      end

      it 'returns status 200' do
        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'POST resolve' do
    before do
      sign_in user
    end

    context "when the user is not authorized to resolve the discussion" do
      it "returns status 404" do
        post :resolve, params: request_params

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
          post :resolve, params: request_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "resolves the discussion" do
          post :resolve, params: request_params

          expect(note.reload.discussion.resolved?).to be true
          expect(note.reload.discussion.resolved_by).to eq(user)
        end

        it "sends notifications if all discussions are resolved" do
          expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
            expect(instance).to receive(:execute).with(merge_request)
          end

          post :resolve, params: request_params
        end

        it "returns the name of the resolving user" do
          post :resolve, params: request_params

          expect(json_response['resolved_by']['name']).to eq(user.name)
        end

        it "returns status 200" do
          post :resolve, params: request_params

          expect(response).to have_gitlab_http_status(200)
        end

        it "renders discussion with serializer" do
          expect_next_instance_of(DiscussionSerializer) do |instance|
            expect(instance).to receive(:represent)
              .with(instance_of(Discussion), { context: instance_of(described_class), render_truncated_diff_lines: true })
          end

          post :resolve, params: request_params
        end

        context 'diff discussion' do
          let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
          let(:discussion) { note.discussion }

          it "returns truncated diff lines" do
            post :resolve, params: request_params

            expect(json_response['truncated_diff_lines']).to be_present
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
        delete :unresolve, params: request_params

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
          delete :unresolve, params: request_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "when the discussion is resolvable" do
        it "unresolves the discussion" do
          delete :unresolve, params: request_params

          expect(note.reload.discussion.resolved?).to be false
        end

        it "returns status 200" do
          delete :unresolve, params: request_params

          expect(response).to have_gitlab_http_status(200)
        end

        context "when vue_mr_discussions cookie is present" do
          before do
            cookies[:vue_mr_discussions] = 'true'
          end

          it "renders discussion with serializer" do
            expect_next_instance_of(DiscussionSerializer) do |instance|
              expect(instance).to receive(:represent)
                .with(instance_of(Discussion), { context: instance_of(described_class), render_truncated_diff_lines: true })
            end

            delete :unresolve, params: request_params
          end
        end
      end
    end
  end
end
