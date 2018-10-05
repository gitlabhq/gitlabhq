# frozen_string_literal: true
require 'spec_helper'

describe DraftNotes::PublishService do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }

  def publish(id: nil)
    DraftNotes::PublishService.new(merge_request, user).execute(id)
  end

  it 'publishes a single draft note' do
    drafts = create_list(:draft_note, 2, merge_request: merge_request, author: user)

    expect { publish(id: drafts.first.id) }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
    expect(DraftNote.count).to eq(1)
  end

  it 'publishes all draft notes for a user in a merge request' do
    create_list(:draft_note, 2, merge_request: merge_request, author: user)

    expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2)
    expect(DraftNote.count).to eq(0)
  end

  it 'only publishes the draft notes belonging to the current user' do
    other_user = create(:user)
    project.add_maintainer(other_user)

    create_list(:draft_note, 2, merge_request: merge_request, author: user)
    create_list(:draft_note, 2, merge_request: merge_request, author: other_user)

    expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2)
    expect(DraftNote.count).to eq(2)
  end

  context 'with quick actions' do
    it 'performs quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "thanks\n/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(2)
      expect(merge_request.reload.assignee).to eq(user)
      expect(merge_request.notes.last).to be_system
    end

    it 'does not create a note if it only contains quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(merge_request.reload.assignee).to eq(user)
      expect(merge_request.notes.last).to be_system
    end
  end

  context 'with drafts that resolve discussions' do
    let(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let(:draft_note) { create(:draft_note, merge_request: merge_request, author: user, resolve_discussion: true, discussion_id: note.discussion.reply_id) }

    it 'resolves the discussion' do
      publish(id: draft_note.id)

      expect(note.discussion.resolved?).to be true
    end

    it 'sends notifications if all discussions are resolved' do
      expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

      publish
    end
  end
end
