# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::MergeRequests::DraftsController, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project, author: create(:user)) }
  let(:user) { project.first_owner }
  let_it_be(:user2) { create(:user) }

  let(:params) do
    {
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      merge_request_id: merge_request.iid
    }
  end

  before do
    create(:merge_request_reviewer, merge_request: merge_request, reviewer: user)

    sign_in(user)
    stub_licensed_features(multiple_merge_request_assignees: true)
    stub_commonmark_sourcepos_disabled
  end

  describe 'GET #index' do
    let!(:draft_note) { create(:draft_note, merge_request: merge_request, author: user) }

    it 'list merge request draft notes for current user' do
      get :index, params: params

      expect(json_response.first['merge_request_id']).to eq(merge_request.id)
      expect(json_response.first['author']['id']).to eq(user.id)
      expect(json_response.first['note_html']).not_to be_empty
    end
  end

  describe 'POST #create' do
    def create_draft_note(draft_overrides: {}, overrides: {})
      post_params = params.merge({
        draft_note: {
          note: 'This is a unpublished comment'
        }.merge(draft_overrides)
      }.merge(overrides))

      post :create, params: post_params
    end

    context 'without permissions' do
      let(:project) { create(:project, :private) }

      before do
        sign_in(user2)
      end

      it 'does not allow draft note creation' do
        expect { create_draft_note }.not_to change { DraftNote.count }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'creates a draft note' do
      expect(Banzai::Renderer).to receive(:render).once.and_call_original

      expect { create_draft_note }.to change { DraftNote.count }.by(1)
    end

    it 'creates an internal draft note' do
      create_draft_note(draft_overrides: { internal: true })

      draft_note = DraftNote.find_by(author: user)

      expect(draft_note.internal).to eq(true)
    end

    it 'creates draft note with position' do
      diff_refs = project.commit(sample_commit.id).try(:diff_refs)

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: diff_refs
      )

      create_draft_note(draft_overrides: { position: position.to_json })

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['position']).to be_present
      expect(json_response['file_hash']).to be_present
      expect(json_response['file_identifier_hash']).to be_present
      expect(json_response['line_code']).to match(/\w+_\d+_\d+/)
      expect(json_response['note_html']).to eq('<p dir="auto">This is a unpublished comment</p>')
    end

    it 'creates a draft note with quick actions' do
      stub_commonmark_sourcepos_enabled
      create_draft_note(draft_overrides: { note: "#{user2.to_reference}\n/assign #{user.to_reference}" })

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['note_html']).to match(/#{user2.to_reference}/)
      expect(json_response['references']['commands']).to match(/Assigns/)
      expect(json_response['references']['users']).to include(user2.username)
    end

    context 'in a thread' do
      let(:discussion) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project).discussion }

      it 'creates draft note as a reply' do
        expect do
          create_draft_note(overrides: { in_reply_to_discussion_id: discussion.reply_id })
        end.to change { DraftNote.count }.by(1)

        draft_note = DraftNote.last

        expect(draft_note).to be_valid
        expect(draft_note.discussion_id).to eq(discussion.reply_id)
      end

      it 'creates a draft note that will resolve a thread' do
        expect do
          create_draft_note(
            overrides: { in_reply_to_discussion_id: discussion.reply_id },
            draft_overrides: { resolve_discussion: true }
          )
        end.to change { DraftNote.count }.by(1)

        draft_note = DraftNote.last

        expect(draft_note).to be_valid
        expect(draft_note.discussion_id).to eq(discussion.reply_id)
        expect(draft_note.resolve_discussion).to eq(true)
      end

      it 'cannot create more than one draft note per thread' do
        expect do
          create_draft_note(
            overrides: { in_reply_to_discussion_id: discussion.reply_id },
            draft_overrides: { resolve_discussion: true }
          )
        end.to change { DraftNote.count }.by(1)

        expect do
          create_draft_note(
            overrides: { in_reply_to_discussion_id: discussion.reply_id },
            draft_overrides: { resolve_discussion: true, note: 'A note' }
          )
        end.to not_change { DraftNote.count }
      end
    end

    context 'commit_id is present' do
      let(:commit) { project.commit(sample_commit.id) }

      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: 14,
          diff_refs: commit.diff_refs
        )
      end

      before do
        create_draft_note(draft_overrides: { commit_id: commit_id, position: position.to_json })
      end

      context 'value is a commit sha' do
        let(:commit_id) { commit.id }

        it 'creates the draft note with commit ID' do
          expect(DraftNote.last.commit_id).to eq(commit_id)
        end
      end

      context 'value is "undefined"' do
        let(:commit_id) { 'undefined' }

        it 'creates the draft note with nil commit ID' do
          expect(DraftNote.last.commit_id).to be_nil
        end
      end
    end

    context 'when the draft note is invalid' do
      let_it_be(:draft_note) { DraftNote.new }

      before do
        errors = ActiveModel::Errors.new(draft_note)
        errors.add(:base, 'Error 1')
        errors.add(:base, 'Error 2')

        allow(draft_note).to receive(:errors).and_return(errors)

        allow_next_instance_of(DraftNotes::CreateService) do |service|
          allow(service).to receive(:execute).and_return(draft_note)
        end
      end

      it 'does not allow draft note creation' do
        expect { create_draft_note }.not_to change { DraftNote.count }
      end

      it "returns status 422", :aggregate_failures do
        create_draft_note

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.body).to eq('{"errors":"Error 1 and Error 2"}')
      end
    end

    context 'when type is present in draft note params' do
      it 'assign note_type to draft note' do
        create_draft_note(draft_overrides: { type: 'DiscussionNote' })

        draft_note = DraftNote.find_by(author: user)

        expect(draft_note.note_type).to eq('DiscussionNote')
      end
    end
  end

  describe 'PUT #update' do
    let(:draft) { create(:draft_note, merge_request: merge_request, author: user) }

    def update_draft_note(overrides = {})
      put_params = params.merge({
        id: draft.id,
        draft_note: {
          note: 'This is an updated unpublished comment'
        }.merge(overrides)
      })

      put :update, params: put_params
    end

    context 'without permissions' do
      before_all do
        project.add_developer(user2)
      end

      before do
        sign_in(user2)
      end

      it 'does not allow editing draft note belonging to someone else' do
        update_draft_note

        expect(response).to have_gitlab_http_status(:not_found)
        expect(draft.reload.note).not_to eq('This is an updated unpublished comment')
      end
    end

    it 'updates the draft' do
      expect(draft.note).not_to be_empty

      expect { update_draft_note }.not_to change { DraftNote.count }

      draft.reload

      expect(draft.note).to eq('This is an updated unpublished comment')
      expect(json_response['note_html']).not_to be_empty
    end

    context 'when the draft note is invalid' do
      before do
        errors = ActiveModel::Errors.new(draft)
        errors.add(:base, 'Error 1')
        errors.add(:base, 'Error 2')

        allow_next_found_instance_of(DraftNote) do |instance|
          allow(instance).to receive(:update).and_return(false)
          allow(instance).to receive(:errors).and_return(errors)
        end
      end

      it 'does not update the draft' do
        expect { update_draft_note }.not_to change { draft.reload.note }
      end

      it 'returns status 422', :aggregate_failures do
        update_draft_note

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.body).to eq('{"errors":"Error 1 and Error 2"}')
      end
    end
  end

  describe 'POST #publish' do
    context 'without permissions' do
      shared_examples_for 'action that does not allow publishing draft note' do
        it 'does not allow publishing draft note' do
          expect { action }
            .to not_change { Note.count }
            .and not_change { DraftNote.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      before do
        sign_in(user2)
      end

      context 'when note belongs to someone else' do
        before_all do
          project.add_developer(user2)
        end

        it_behaves_like 'action that does not allow publishing draft note' do
          let!(:draft) { create(:draft_note, merge_request: merge_request, author: user) }
          let(:action) { post :publish, params: params.merge(id: draft.id) }
        end
      end

      context 'when merge request discussion is locked' do
        let(:project) { create(:project, :public, :merge_requests_public, :repository) }

        before do
          create(:draft_note, merge_request: merge_request, author: user2)
          merge_request.update!(discussion_locked: true)
        end

        it_behaves_like 'action that does not allow publishing draft note' do
          let(:action) { post :publish, params: params }
        end
      end
    end

    context 'when PublishService errors' do
      it 'returns message and 500 response' do
        create(:draft_note, merge_request: merge_request, author: user)
        error_message = "Something went wrong"

        expect_next_instance_of(DraftNotes::PublishService) do |service|
          allow(service).to receive(:execute).and_return({ message: error_message, status: :error })
        end

        post :publish, params: params

        expect(response).to have_gitlab_http_status(:error)
        expect(json_response["message"]).to include(error_message)
      end
    end

    it 'publishes draft notes with position' do
      diff_refs = project.commit(sample_commit.id).try(:diff_refs)

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: diff_refs
      )

      draft = create(:draft_note_on_text_diff, merge_request: merge_request, author: user, position: position)

      expect { post :publish, params: params }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)

      note = merge_request.notes.reload.last

      expect(note.note).to eq(draft.note)
      expect(note.position).to eq(draft.position)
    end

    it 'does nothing if there are no draft notes' do
      expect { post :publish, params: params }
        .to not_change { Note.count }
        .and not_change { DraftNote.count }
    end

    it 'publishes a draft note with quick actions and applies them', :sidekiq_inline do
      stub_commonmark_sourcepos_enabled
      project.add_developer(user2)
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user2.to_reference}")

      expect(merge_request.assignees).to be_empty

      expect { post :publish, params: params }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
      expect(merge_request.reload.assignee_ids).to match_array([user2.id])
      expect(Note.last.system?).to be true
    end

    it 'publishes all draft notes for an MR' do
      draft_params = { merge_request: merge_request, author: user }

      drafts = create_list(:draft_note, 4, draft_params)

      note = create(:discussion_note_on_merge_request, noteable: merge_request, project: project)
      draft_reply = create(:draft_note, draft_params.merge(discussion_id: note.discussion_id))

      diff_note = create(:diff_note_on_merge_request, noteable: merge_request, project: project)
      diff_draft_reply = create(:draft_note, draft_params.merge(discussion_id: diff_note.discussion_id))

      expect { post :publish, params: params }.to change { Note.count }.by(6)
        .and change { DraftNote.count }.by(-6)

      expect(response).to have_gitlab_http_status(:ok)

      notes = merge_request.notes.reload

      expect(notes.pluck(:note)).to include(*drafts.map(&:note))

      # discussion is memoized and reload doesn't clear the memoization
      expect(Note.find(note.id).discussion.notes.last.note).to eq(draft_reply.note)
      expect(Note.find(diff_note.id).discussion.notes.last.note).to eq(diff_draft_reply.note)
    end

    it 'publishes draft notes by ID' do
      draft1 = create(:draft_note, merge_request: merge_request, author: user)
      create(:draft_note, merge_request: merge_request, author: user)

      expect { post :publish, params: params.merge!(ids: [draft1.id]) }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'can publish just a single draft note' do
      draft_params = { merge_request: merge_request, author: user }

      drafts = create_list(:draft_note, 4, draft_params)

      expect { post :publish, params: params.merge(id: drafts.first.id) }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)
    end

    context 'when publishing drafts in a thread' do
      let(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

      def create_reply(discussion_id, resolves: false)
        create(
          :draft_note,
          merge_request: merge_request,
          author: user,
          discussion_id: discussion_id,
          resolve_discussion: resolves
        )
      end

      it 'resolves a thread if the draft note resolves it' do
        draft_reply = create_reply(note.discussion_id, resolves: true)

        post :publish, params: params

        discussion = note.discussion

        expect(discussion.notes.last.note).to eq(draft_reply.note)
        expect(discussion.resolved?).to eq(true)
        expect(discussion.resolved_by.id).to eq(user.id)
      end

      it 'unresolves a thread if the draft note unresolves it' do
        note.discussion.resolve!(user)
        expect(note.discussion.resolved?).to eq(true)

        draft_reply = create_reply(note.discussion_id, resolves: false)

        post :publish, params: params

        # discussion is memoized and reload doesn't clear the memoization
        discussion = Note.find(note.id).discussion

        expect(discussion.notes.last.note).to eq(draft_reply.note)
        expect(discussion.resolved?).to eq(false)
      end
    end

    context 'publish with note' do
      before do
        allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_submit_review_comment)

        create(:draft_note, merge_request: merge_request, author: user)
      end

      it 'creates note' do
        post :publish, params: params.merge!(note: 'Hello world')

        expect(merge_request.notes.reload.size).to be(2)
      end

      it 'does not create note when note param is empty' do
        post :publish, params: params.merge!(note: '')

        expect(merge_request.notes.reload.size).to be(1)
      end

      it 'tracks merge request activity' do
        post :publish, params: params.merge!(note: 'Hello world')

        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to have_received(:track_submit_review_comment).with(user: user)
      end
    end

    context 'reviewer state' do
      before do
        create(:draft_note, merge_request: merge_request, author: user)
      end

      it 'updates reviewers state' do
        post :publish, params: params.merge!(reviewer_state: 'requested_changes')

        expect(merge_request.merge_request_reviewers.reload[0].state).to eq('requested_changes')
      end

      it 'approves merge request' do
        post :publish, params: params.merge!(reviewer_state: 'approved')

        expect(merge_request.approvals.reload.size).to eq(1)
      end
    end

    context 'approve merge request' do
      before do
        allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_submit_review_approve)

        create(:draft_note, merge_request: merge_request, author: user)
      end

      it 'approves merge request' do
        post :publish, params: params.merge!(reviewer_state: 'approved')

        expect(merge_request.approvals.reload.size).to be(1)
      end

      it 'does not approve merge request' do
        post :publish, params: params.merge!(reviewer_state: 'reviewed')

        expect(merge_request.approvals.reload.size).to be(0)
      end

      it 'tracks merge request activity' do
        post :publish, params: params.merge!(reviewer_state: 'approved')

        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to have_received(:track_submit_review_approve).with(user: user)
      end

      context 'when merge request is already approved by user' do
        before do
          create(:approval, merge_request: merge_request, user: user)
        end

        it 'does return 200' do
          post :publish, params: params.merge!(reviewer_state: 'approved')

          expect(response).to have_gitlab_http_status(:ok)

          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_submit_review_approve).with(user: user)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:draft) { create(:draft_note, merge_request: merge_request, author: user) }

    def create_draft
      create(:draft_note, merge_request: merge_request, author: user)
    end

    context 'without permissions' do
      before_all do
        project.add_developer(user2)
      end

      before do
        sign_in(user2)
      end

      it 'does not allow destroying a draft note belonging to someone else' do
        draft = create(:draft_note, merge_request: merge_request, author: user)

        expect { post :destroy, params: params.merge(id: draft.id) }
          .not_to change { DraftNote.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'destroys the draft note when ID is given' do
      draft = create_draft

      expect { delete :destroy, params: params.merge(id: draft.id) }.to change { DraftNote.count }.by(-1)
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'without permissions' do
      before do
        sign_in(user2)
      end

      it 'does not allow editing draft note belonging to someone else' do
        draft = create_draft

        expect { delete :destroy, params: params.merge(id: draft.id) }.to not_change { DraftNote.count }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #discard' do
    it 'deletes all DraftNotes belonging to a user in a Merge Request' do
      create_list(:draft_note, 6, merge_request: merge_request, author: user)

      expect { delete :discard, params: params }.to change { DraftNote.count }.by(-6)
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'without permissions' do
      before_all do
        project.add_developer(user2)
      end

      before do
        sign_in(user2)
      end

      it 'does not destroys a draft note belonging to someone else' do
        create(:draft_note, merge_request: merge_request, author: user)

        expect { post :discard, params: params }
          .not_to change { DraftNote.count }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
