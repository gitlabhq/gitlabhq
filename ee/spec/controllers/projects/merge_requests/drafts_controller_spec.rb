# frozen_string_literal: true
require 'spec_helper'

describe Projects::MergeRequests::DraftsController do
  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:user)          { project.owner }
  let(:user2)         { create(:user) }

  let(:params) do
    {
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      merge_request_id: merge_request.iid
    }
  end

  before do
    sign_in(user)
    stub_licensed_features(batch_comments: true)
  end

  describe 'GET #index' do
    let!(:draft_note) { create(:draft_note, merge_request: merge_request, author: user) }

    it 'list merge request draft notes for current user' do
      get :index, params

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

      post :create, post_params
    end

    context 'without permissions' do
      let(:project) { create(:project, :private) }

      before do
        sign_in(user2)
      end

      it 'does not allow draft note creation' do
        expect { create_draft_note }.to change { DraftNote.count }.by(0)
        expect(response).to have_gitlab_http_status(404)
      end
    end

    it 'creates a draft note' do
      expect { create_draft_note }.to change { DraftNote.count }.by(1)
    end

    it 'creates draft note with position' do
      diff_refs = project.commit(RepoHelpers.sample_commit.id).try(:diff_refs)

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: diff_refs
      )

      create_draft_note(draft_overrides: { position: position.to_json })

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['position']).to be_present
      expect(json_response['file_hash']).to be_present
      expect(json_response['line_code']).to match(/\w+_\d+_\d+/)
      expect(json_response['note_html']).to eq('<p dir="auto">This is a unpublished comment</p>')
    end

    it 'creates a draft note with quick actions' do
      create_draft_note(draft_overrides: { note: "#{user2.to_reference}\n/assign #{user.to_reference}" })

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['note_html']).to match(/#{user2.to_reference}/)
      expect(json_response['references']['commands']).to match(/Assigns/)
      expect(json_response['references']['users']).to include(user2.username)
    end

    context 'in a discussion' do
      let(:discussion) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project).discussion }

      it 'creates draft note as a reply' do
        expect do
          create_draft_note(overrides: { in_reply_to_discussion_id: discussion.reply_id })
        end.to change { DraftNote.count }.by(1)

        draft_note = DraftNote.last

        expect(draft_note).to be_valid
        expect(draft_note.discussion_id).to eq(discussion.reply_id)
      end

      it 'creates a draft note that will resolve a discussion' do
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

      it 'cannot create more than one draft note per discussion' do
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
        end.to change { DraftNote.count }.by(0)
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

      put :update, put_params
    end

    context 'without permissions' do
      before do
        sign_in(user2)
      end

      it 'does not allow editing draft note belonging to someone else' do
        update_draft_note

        expect(response).to have_gitlab_http_status(404)
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
  end

  describe 'POST #publish' do
    it 'publishes draft notes with position' do
      diff_refs = project.commit(RepoHelpers.sample_commit.id).try(:diff_refs)

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: diff_refs
      )

      draft = create(:draft_note_on_text_diff, merge_request: merge_request, author: user, position: position)

      expect { post :publish, params }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)

      note = merge_request.notes.reload.last

      expect(note.note).to eq(draft.note)
      expect(note.position).to eq(draft.position)
    end

    it 'does nothing if there are no draft notes' do
      expect { post :publish, params }.to change { Note.count }.by(0).and change { DraftNote.count }.by(0)
    end

    it 'publishes a draft note with quick actions and applies them' do
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user.to_reference}")

      expect(merge_request.assignee_id).to be_nil

      expect { post :publish, params }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)

      expect(response).to have_gitlab_http_status(200)
      expect(merge_request.reload.assignee_id).to eq(user.id)
      expect(Note.last.system?).to be true
    end

    it 'publishes all draft notes for an MR' do
      draft_params = { merge_request: merge_request, author: user }

      drafts = create_list(:draft_note, 4, draft_params)

      note = create(:discussion_note_on_merge_request, noteable: merge_request, project: project)
      draft_reply = create(:draft_note, draft_params.merge(discussion_id: note.discussion_id))

      diff_note = create(:diff_note_on_merge_request, noteable: merge_request, project: project)
      diff_draft_reply = create(:draft_note, draft_params.merge(discussion_id: diff_note.discussion_id))

      expect { post :publish, params }.to change { Note.count }.by(6)
        .and change { DraftNote.count }.by(-6)

      expect(response).to have_gitlab_http_status(200)

      notes = merge_request.notes.reload

      expect(notes.pluck(:note)).to include(*drafts.map(&:note))
      expect(note.discussion.notes.last.note).to eq(draft_reply.note)
      expect(diff_note.discussion.notes.last.note).to eq(diff_draft_reply.note)
    end

    it 'can publish just a single draft note' do
      draft_params = { merge_request: merge_request, author: user }

      drafts = create_list(:draft_note, 4, draft_params)

      expect { post :publish, params.merge(id: drafts.first.id) }.to change { Note.count }.by(1)
        .and change { DraftNote.count }.by(-1)
    end

    context 'when publishing drafts in a discussion' do
      let(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

      def create_reply(discussion_id, resolves: false)
        create(:draft_note,
               merge_request: merge_request,
               author: user,
               discussion_id: discussion_id,
               resolve_discussion: resolves
              )
      end

      it 'resolves a discussion if the draft note resolves it' do
        draft_reply = create_reply(note.discussion_id, resolves: true)

        post :publish, params

        discussion = note.discussion

        expect(discussion.notes.last.note).to eq(draft_reply.note)
        expect(discussion.resolved?).to eq(true)
        expect(discussion.resolved_by.id).to eq(user.id)
      end

      it 'unresolves a discussion if the draft note unresolves it' do
        note.discussion.resolve!(user)
        expect(note.discussion.resolved?).to eq(true)

        draft_reply = create_reply(note.discussion_id, resolves: false)

        post :publish, params

        discussion = note.discussion

        expect(discussion.notes.last.note).to eq(draft_reply.note)
        expect(discussion.resolved?).to eq(false)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:draft) { create(:draft_note, merge_request: merge_request, author: user) }

    def create_draft
      create(:draft_note, merge_request: merge_request, author: user)
    end

    it 'destroys the draft note' do
      draft = create_draft

      expect { delete :destroy, params.merge(id: draft.id) }.to change { DraftNote.count }.by(-1)
      expect(response).to have_gitlab_http_status(200)
    end

    context 'without permissions' do
      before do
        sign_in(user2)
      end

      it 'does not allow editing draft note belonging to someone else' do
        draft = create_draft

        expect { delete :destroy, params.merge(id: draft.id) }.to change { DraftNote.count }.by(0)
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE #discard' do
    it 'deletes all DraftNotes belonging to a user in a Merge Request' do
      create_list(:draft_note, 6, merge_request: merge_request, author: user)

      expect { delete :discard, params }.to change { DraftNote.count }.by(-6)
      expect(response).to have_gitlab_http_status(200)
    end
  end

  shared_examples_for 'batch comments feature disabled' do
    context 'GET #index' do
      it 'does not return existing drafts' do
        create_list(:draft_note, 4, merge_request: merge_request, author: user)

        get :index, params

        expect(json_response).to eq([])
      end
    end

    context 'POST #create' do
      it 'errors out' do
        expect do
          post :create, params.merge(draft_note: { note: 'comment' })
        end.to change { DraftNote.count }.by(0)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'PUT #update' do
      it 'errors out' do
        draft = create(:draft_note, merge_request: merge_request, author: user)

        expect do
          put :update, params.merge(id: draft.id, draft_note: { note: 'comment' })
        end.to change { DraftNote.count }.by(0)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'DELETE #destroy' do
      it 'errors out' do
        draft = create(:draft_note, merge_request: merge_request, author: user)

        expect { delete :destroy, params.merge(id: draft.id) }.to change { DraftNote.count }.by(0)
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'collection endpoints' do
      before do
        create_list(:draft_note, 5, merge_request: merge_request, author: user)
      end

      context 'POST #publish' do
        it 'errors out' do
          expect do
            post :publish, params
          end.to change { DraftNote.count }.by(0).and change { Note.count }.by(0)

          expect(response).to have_gitlab_http_status(403)
          expect(DraftNote.count).to eq(5)
        end
      end

      context 'DELETE #discard' do
        it 'errors out' do
          expect do
            delete :discard, params
          end.to change { DraftNote.count }.by(0)

          expect(response).to have_gitlab_http_status(403)
          expect(DraftNote.count).to eq(5)
        end
      end
    end
  end

  context 'disabled due to license' do
    before do
      stub_licensed_features(batch_comments: false)
    end

    it_behaves_like 'batch comments feature disabled'
  end

  context 'disabled via feature flag' do
    before do
      stub_feature_flags(batch_comments: false)
    end

    it_behaves_like 'batch comments feature disabled'
  end
end
