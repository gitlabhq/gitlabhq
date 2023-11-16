# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DiscussionsController, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:note, reload: true) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
  let_it_be(:user) { create(:user) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      noteable_type: 'merge_requests',
      noteable_id: merge_request,
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authorized to read the MR' do
      before_all do
        project.add_reporter(user)
      end

      it 'returns status 200' do
        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns status 404 if MR does not exists' do
        get :show, params: request_params.merge(noteable_id: non_existing_record_id), session: { format: :json }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authorized but note is LegacyDiffNote' do
      before_all do
        project.add_developer(user)
      end

      it 'returns status 200' do
        note.update!(type: 'LegacyDiffNote')

        get :show, params: request_params, session: { format: :json }

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before_all do
        project.add_developer(user)
      end

      context "when the discussion is not resolvable" do
        before do
          note.update!(system: true)
        end

        it "returns status 404" do
          post :resolve, params: request_params

          expect(response).to have_gitlab_http_status(:not_found)
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

          expect(response).to have_gitlab_http_status(:ok)
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

          it "returns truncated diff lines" do
            post :resolve, params: request_params

            expect(json_response['truncated_diff_lines']).to be_present
          end
        end
      end

      context 'on an Issue' do
        let_it_be(:note, reload: true) { create(:discussion_note_on_issue, noteable: issue, project: project) }

        let(:request_params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            noteable_type: 'issues',
            noteable_id: issue,
            id: note.discussion_id
          }
        end

        it 'resolves the discussion and returns status 200' do
          post :resolve, params: request_params

          expect(note.reload.resolved_at).not_to be_nil
          expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when the user is authorized to resolve the discussion" do
      before_all do
        project.add_developer(user)
      end

      context "when the discussion is not resolvable" do
        before do
          note.update!(system: true)
        end

        it "returns status 404" do
          delete :unresolve, params: request_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when the discussion is resolvable" do
        it "unresolves the discussion" do
          delete :unresolve, params: request_params

          # discussion is memoized and reload doesn't clear the memoization
          expect(Note.find(note.id).discussion.resolved?).to be false
        end

        it "tracks thread unresolve usage data" do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_unresolve_thread_action).with(user: user)

          delete :unresolve, params: request_params
        end

        it "returns status 200" do
          delete :unresolve, params: request_params

          expect(response).to have_gitlab_http_status(:ok)
        end

        it "renders discussion with serializer" do
          expect_next_instance_of(DiscussionSerializer) do |instance|
            expect(instance).to receive(:represent)
              .with(instance_of(Discussion), { context: instance_of(described_class), render_truncated_diff_lines: true })
          end

          delete :unresolve, params: request_params
        end
      end

      context 'on an Issue' do
        let_it_be(:note, reload: true) { create(:discussion_note_on_issue, noteable: issue, project: project) }

        let(:request_params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            noteable_type: 'issues',
            noteable_id: issue,
            id: note.discussion_id
          }
        end

        it 'unresolves the discussion and returns status 200' do
          delete :unresolve, params: request_params

          expect(note.reload.resolved_at).to be_nil
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
