import { computed } from 'vue';
import { defineStore } from 'pinia';
import { useNotes } from '~/notes/store/legacy_notes';
import { useDiscussions } from '~/notes/store/discussions';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import {
  buildLineDiscussionData,
  buildReplyData,
  buildUpdateNoteData,
} from '~/merge_request/utils';

export const useMergeRequestDiscussions = defineStore('mergeRequestDiscussions', () => {
  const diffDiscussions = useDiffDiscussions();

  async function fetchNotes() {
    await useNotes().fetchNotes();
    const discussionsStore = useDiscussions();
    discussionsStore.discussions.forEach((discussion) => {
      if (discussion.resolvable && discussion.resolved) {
        discussionsStore.collapseDiscussion(discussion);
      }
    });
  }

  async function createNewDiscussion(noteData) {
    const notes = useNotes();
    await notes.createNewNote({
      endpoint: notes.noteableData.create_note_path,
      data: { note: noteData },
    });
  }

  async function createLineDiscussion(formDiscussion, noteData) {
    const notes = useNotes();
    const { diffRefs } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        noteData,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        diffRefs,
      }),
    );
    diffDiscussions.removeNewLineDiscussionForm(formDiscussion);
  }

  async function replyToDiscussion(discussion, noteText) {
    const notes = useNotes();
    const { diffRefs } = useMergeRequestVersions();
    await notes.saveNote(
      buildReplyData({
        discussion,
        noteText,
        noteableData: notes.noteableData,
        diffRefs,
      }),
    );
  }

  async function saveNote(note, noteText) {
    const notes = useNotes();
    await notes.updateNote(
      buildUpdateNoteData({
        note,
        noteText,
        noteableData: notes.noteableData,
      }),
    );
  }

  async function destroyNote(note) {
    await useNotes().deleteNote(note);
  }

  async function toggleAwardOnNote(note, name) {
    await useNotes().toggleAwardRequest({
      endpoint: note.toggle_award_path,
      awardName: name,
      noteId: note.id,
    });
  }

  async function toggleResolveNote(discussion) {
    await useNotes().toggleResolveNote({
      endpoint: discussion.resolve_path,
      isResolved: discussion.resolved,
      discussion: true,
      discussionId: discussion.id,
    });
  }

  return {
    fetchNotes,
    createNewDiscussion,
    createLineDiscussion,
    replyToDiscussion,
    saveNote,
    destroyNote,
    toggleAwardOnNote,
    toggleResolveNote,
    setInitialDiscussions: diffDiscussions.setInitialDiscussions,
    replaceDiscussion: diffDiscussions.replaceDiscussion,
    updateDiscussion: diffDiscussions.updateDiscussion,
    toggleDiscussionReplies: diffDiscussions.toggleDiscussionReplies,
    expandDiscussionReplies: diffDiscussions.expandDiscussionReplies,
    startReplying: diffDiscussions.startReplying,
    stopReplying: diffDiscussions.stopReplying,
    addNote: diffDiscussions.addNote,
    updateNote: diffDiscussions.updateNote,
    updateNoteTextById: diffDiscussions.updateNoteTextById,
    editNote: diffDiscussions.editNote,
    deleteNote: diffDiscussions.deleteNote,
    addDiscussion: diffDiscussions.addDiscussion,
    deleteDiscussion: diffDiscussions.deleteDiscussion,
    setEditingMode: diffDiscussions.setEditingMode,
    requestLastNoteEditing: diffDiscussions.requestLastNoteEditing,
    toggleAward: diffDiscussions.toggleAward,
    collapseDiscussion: diffDiscussions.collapseDiscussion,
    expandDiscussion: diffDiscussions.expandDiscussion,
    replyToLineDiscussion: diffDiscussions.addNewLineDiscussionForm,
    addNewLineDiscussionForm: diffDiscussions.addNewLineDiscussionForm,
    replaceDiscussionForm: diffDiscussions.replaceDiscussionForm,
    removeNewLineDiscussionForm: diffDiscussions.removeNewLineDiscussionForm,
    setDiscussionFormText: diffDiscussions.setDiscussionFormText,
    setNewLineDiscussionFormAutofocus: diffDiscussions.setNewLineDiscussionFormAutofocus,
    setFileDiscussionsHidden: diffDiscussions.setFileDiscussionsHidden,
    setPositionDiscussionsHidden: diffDiscussions.setPositionDiscussionsHidden,
    discussionForms: computed(() => diffDiscussions.discussionForms),
    discussionsWithForms: computed(() => diffDiscussions.discussionsWithForms),
    getImageDiscussions: computed(() => diffDiscussions.getImageDiscussions),
    findDiscussionsForPosition: computed(() => diffDiscussions.findDiscussionsForPosition),
    findDiscussionsForFile: computed(() => diffDiscussions.findDiscussionsForFile),
    findAllDiscussionsForFile: computed(() => diffDiscussions.findAllDiscussionsForFile),
    findVisibleDiscussionsForFile: computed(() => diffDiscussions.findVisibleDiscussionsForFile),
    findFileDiscussionsForFile: computed(() => diffDiscussions.findFileDiscussionsForFile),
    addNewFileDiscussionForm: diffDiscussions.addNewFileDiscussionForm,
    removeNewFileDiscussionForm: diffDiscussions.removeNewFileDiscussionForm,
  };
});
