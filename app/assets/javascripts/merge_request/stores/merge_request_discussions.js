import { computed } from 'vue';
import { defineStore } from 'pinia';
import { useNotes } from '~/notes/store/legacy_notes';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

export const useMergeRequestDiscussions = defineStore('mergeRequestDiscussions', () => {
  const diffDiscussions = useDiffDiscussions();

  async function fetchNotes() {
    const notesStore = useNotes();
    await notesStore.fetchNotes();
  }

  return {
    fetchNotes,
    setInitialDiscussions: diffDiscussions.setInitialDiscussions,
    replaceDiscussion: diffDiscussions.replaceDiscussion,
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
    replyToLineDiscussion: diffDiscussions.replyToLineDiscussion,
    addNewLineDiscussionForm: diffDiscussions.addNewLineDiscussionForm,
    replaceDiscussionForm: diffDiscussions.replaceDiscussionForm,
    removeNewLineDiscussionForm: diffDiscussions.removeNewLineDiscussionForm,
    setNewLineDiscussionFormText: diffDiscussions.setNewLineDiscussionFormText,
    setNewLineDiscussionFormAutofocus: diffDiscussions.setNewLineDiscussionFormAutofocus,
    setFileDiscussionsHidden: diffDiscussions.setFileDiscussionsHidden,
    discussionForms: computed(() => diffDiscussions.discussionForms),
    discussionsWithForms: computed(() => diffDiscussions.discussionsWithForms),
    getImageDiscussions: computed(() => diffDiscussions.getImageDiscussions),
    findDiscussionsForPosition: computed(() => diffDiscussions.findDiscussionsForPosition),
    findDiscussionsForFile: computed(() => diffDiscussions.findDiscussionsForFile),
    findAllDiscussionsForFile: computed(() => diffDiscussions.findAllDiscussionsForFile),
    findVisibleDiscussionsForFile: computed(() => diffDiscussions.findVisibleDiscussionsForFile),
  };
});
