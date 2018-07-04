require 'spec_helper'

describe Projects::NotesController do
  include ProjectForksHelper

  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }
  let(:note)    { create(:note, noteable: issue, project: project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: note
    }
  end

  describe 'GET index' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        target_type: 'issue',
        target_id: issue.id,
        format: 'json'
      }
    end

    let(:parsed_response) { JSON.parse(response.body).with_indifferent_access }
    let(:note_json) { parsed_response[:notes].first }

    before do
      sign_in(user)
      project.add_developer(user)
    end

    it 'passes last_fetched_at from headers to NotesFinder' do
      last_fetched_at = 3.hours.ago.to_i

      request.headers['X-Last-Fetched-At'] = last_fetched_at

      expect(NotesFinder).to receive(:new)
        .with(anything, anything, hash_including(last_fetched_at: last_fetched_at))
        .and_call_original

      get :index, request_params
    end

    context 'for a discussion note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:discussion_note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:discussion_html]).not_to be_nil
        expect(note_json[:diff_discussion_html]).to be_nil
        expect(note_json[:discussion_line_code]).to be_nil
      end
    end

    context 'for a diff discussion note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:diff_note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:discussion_html]).not_to be_nil
        expect(note_json[:diff_discussion_html]).not_to be_nil
        expect(note_json[:discussion_line_code]).not_to be_nil
      end
    end

    context 'for a commit note' do
      let(:project) { create(:project, :repository) }
      let!(:note) { create(:note_on_commit, project: project) }

      context 'when displayed on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        let(:params) { request_params.merge(target_type: 'merge_request', target_id: merge_request.id, html: true) }

        it 'responds with the expected attributes' do
          get :index, params

          expect(note_json[:id]).to eq(note.id)
          expect(note_json[:discussion_html]).not_to be_nil
          expect(note_json[:diff_discussion_html]).to be_nil
          expect(note_json[:discussion_line_code]).to be_nil
        end
      end

      context 'when displayed on the commit' do
        let(:params) { request_params.merge(target_type: 'commit', target_id: note.commit_id, html: true) }

        it 'responds with the expected attributes' do
          get :index, params

          expect(note_json[:id]).to eq(note.id)
          expect(note_json[:discussion_html]).to be_nil
          expect(note_json[:diff_discussion_html]).to be_nil
          expect(note_json[:discussion_line_code]).to be_nil
        end

        context 'when user cannot read commit' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :download_code, project).and_return(false)
          end

          it 'renders 404' do
            get :index, params

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end

    context 'for a regular note' do
      let!(:note) { create(:note_on_merge_request, project: project) }

      let(:params) { request_params.merge(target_type: 'merge_request', target_id: note.noteable_id, html: true) }

      it 'responds with the expected attributes' do
        get :index, params

        expect(note_json[:id]).to eq(note.id)
        expect(note_json[:html]).not_to be_nil
        expect(note_json[:discussion_html]).to be_nil
        expect(note_json[:diff_discussion_html]).to be_nil
        expect(note_json[:discussion_line_code]).to be_nil
      end
    end

    context 'with cross-reference system note', :request_store do
      let(:new_issue) { create(:issue) }
      let(:cross_reference) { "mentioned in #{new_issue.to_reference(issue.project)}" }

      before do
        note
        create(:discussion_note_on_issue, :system, noteable: issue, project: issue.project, note: cross_reference)
      end

      it 'filters notes that the user should not see' do
        get :index, request_params

        expect(parsed_response[:notes].count).to eq(1)
        expect(note_json[:id]).to eq(note.id)
      end

      it 'does not result in N+1 queries' do
        # Instantiate the controller variables to ensure QueryRecorder has an accurate base count
        get :index, request_params

        RequestStore.clear!

        control_count = ActiveRecord::QueryRecorder.new do
          get :index, request_params
        end.count

        RequestStore.clear!

        create_list(:discussion_note_on_issue, 2, :system, noteable: issue, project: issue.project, note: cross_reference)

        expect { get :index, request_params }.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe 'POST create' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }
    let(:request_params) do
      {
        note: { note: 'some note', noteable_id: merge_request.id, noteable_type: 'MergeRequest' },
        namespace_id: project.namespace,
        project_id: project,
        merge_request_diff_head_sha: 'sha',
        target_type: 'merge_request',
        target_id: merge_request.id
      }
    end

    before do
      sign_in(user)
      project.add_developer(user)
    end

    it "returns status 302 for html" do
      post :create, request_params

      expect(response).to have_gitlab_http_status(302)
    end

    it "returns status 200 for json" do
      post :create, request_params.merge(format: :json)

      expect(response).to have_gitlab_http_status(200)
    end

    context 'when merge_request_diff_head_sha present' do
      before do
        service_params = {
          note: 'some note',
          noteable_id: merge_request.id.to_s,
          noteable_type: 'MergeRequest',
          merge_request_diff_head_sha: 'sha',
          in_reply_to_discussion_id: nil
        }

        expect(Notes::CreateService).to receive(:new).with(project, user, service_params).and_return(double(execute: true))
      end

      it "returns status 302 for html" do
        post :create, request_params

        expect(response).to have_gitlab_http_status(302)
      end
    end

    context 'when creating a commit comment from an MR fork' do
      let(:project) { create(:project, :repository) }

      let(:forked_project) do
        fork_project(project, nil, repository: true)
      end

      let(:merge_request) do
        create(:merge_request, source_project: forked_project, target_project: project, source_branch: 'feature', target_branch: 'master')
      end

      let(:existing_comment) do
        create(:note_on_commit, note: 'a note', project: forked_project, commit_id: merge_request.commit_shas.first)
      end

      def post_create(extra_params = {})
        post :create, {
               note: { note: 'some other note' },
               namespace_id: project.namespace,
               project_id: project,
               target_type: 'merge_request',
               target_id: merge_request.id,
               note_project_id: forked_project.id,
               in_reply_to_discussion_id: existing_comment.discussion_id
             }.merge(extra_params)
      end

      context 'when the note_project_id is not correct' do
        it 'returns a 404' do
          post_create(note_project_id: Project.maximum(:id).succ)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when the user has no access to the fork' do
        it 'returns a 404' do
          post_create

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when the user has access to the fork' do
        let(:discussion) { forked_project.notes.find_discussion(existing_comment.discussion_id) }

        before do
          forked_project.add_developer(user)

          existing_comment
        end

        it 'creates the note' do
          expect { post_create }.to change { forked_project.notes.count }.by(1)
        end
      end
    end

    context 'when the merge request discussion is locked' do
      before do
        project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        merge_request.update_attribute(:discussion_locked, true)
      end

      context 'when a noteable is not found' do
        it 'returns 404 status' do
          request_params[:target_id] = 9999
          post :create, request_params.merge(format: :json)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when a user is a team member' do
        it 'returns 302 status for html' do
          post :create, request_params

          expect(response).to have_gitlab_http_status(302)
        end

        it 'returns 200 status for json' do
          post :create, request_params.merge(format: :json)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'creates a new note' do
          expect { post :create, request_params }.to change { Note.count }.by(1)
        end
      end

      context 'when a user is not a team member' do
        before do
          project.project_member(user).destroy
        end

        it 'returns 404 status' do
          post :create, request_params

          expect(response).to have_gitlab_http_status(404)
        end

        it 'does not create a new note' do
          expect { post :create, request_params }.not_to change { Note.count }
        end
      end
    end
  end

  describe 'PUT update' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: note,
        format: :json,
        note: {
          note: "New comment"
        }
      }
    end

    before do
      sign_in(note.author)
      project.add_developer(note.author)
    end

    it "updates the note" do
      expect { put :update, request_params }.to change { note.reload.note }
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: note,
        format: :js
      }
    end

    context 'user is the author of a note' do
      before do
        sign_in(note.author)
        project.add_developer(note.author)
      end

      it "returns status 200 for html" do
        delete :destroy, request_params

        expect(response).to have_gitlab_http_status(200)
      end

      it "deletes the note" do
        expect { delete :destroy, request_params }.to change { Note.count }.from(1).to(0)
      end
    end

    context 'user is not the author of a note' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it "returns status 404" do
        delete :destroy, request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    it "toggles the award emoji" do
      expect do
        post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))
      end.to change { note.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
    end

    it "removes the already awarded emoji" do
      post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))

      expect do
        post(:toggle_award_emoji, request_params.merge(name: "thumbsup"))
      end.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe "resolving and unresolving" do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

    describe 'POST resolve' do
      before do
        sign_in user
      end

      context "when the user is not authorized to resolve the note" do
        it "returns status 404" do
          post :resolve, request_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.add_developer(user)
        end

        context "when the note is not resolvable" do
          before do
            note.update(system: true)
          end

          it "returns status 404" do
            post :resolve, request_params

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context "when the note is resolvable" do
          it "resolves the note" do
            post :resolve, request_params

            expect(note.reload.resolved?).to be true
            expect(note.reload.resolved_by).to eq(user)
          end

          it "sends notifications if all discussions are resolved" do
            expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

            post :resolve, request_params
          end

          it "returns the name of the resolving user" do
            post :resolve, request_params.merge(html: true)

            expect(JSON.parse(response.body)["resolved_by"]).to eq(user.name)
          end

          it "returns status 200" do
            post :resolve, request_params

            expect(response).to have_gitlab_http_status(200)
          end
        end
      end
    end

    describe 'DELETE unresolve' do
      before do
        sign_in user

        note.resolve!(user)
      end

      context "when the user is not authorized to resolve the note" do
        it "returns status 404" do
          delete :unresolve, request_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "when the user is authorized to resolve the note" do
        before do
          project.add_developer(user)
        end

        context "when the note is not resolvable" do
          before do
            note.update(system: true)
          end

          it "returns status 404" do
            delete :unresolve, request_params

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context "when the note is resolvable" do
          it "unresolves the note" do
            delete :unresolve, request_params

            expect(note.reload.resolved?).to be false
          end

          it "returns status 200" do
            delete :unresolve, request_params

            expect(response).to have_gitlab_http_status(200)
          end
        end
      end
    end
  end
end
