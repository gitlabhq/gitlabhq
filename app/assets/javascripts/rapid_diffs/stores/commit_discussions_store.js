import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

export const useCommitDiffDiscussions = defineStore('commitDiffDiscussions', () => {
  const diffDiscussions = useDiffDiscussions();
  const endpoint = ref('');

  function setDiscussionsEndpoint(url) {
    endpoint.value = url;
  }

  const timelineDiscussions = computed(() => {
    return diffDiscussions.discussionsWithForms.filter(
      (discussion) => !discussion.isForm && !discussion.diff_discussion,
    );
  });

  async function createNewDiscussion(noteData) {
    const {
      data: { discussion },
    } = await axios.post(endpoint.value, { note: noteData });
    diffDiscussions.addDiscussion(discussion);
  }

  async function createLineDiscussion(formDiscussion, noteData) {
    const {
      data: { discussion },
    } = await axios.post(endpoint.value, { note: noteData });
    diffDiscussions.replaceDiscussionForm(formDiscussion, discussion);
  }

  async function replyToDiscussion(discussion, noteText) {
    const {
      data: { discussion: updated },
    } = await axios.post(endpoint.value, {
      in_reply_to_discussion_id: discussion.reply_id,
      note: { note: noteText },
    });
    diffDiscussions.replaceDiscussion(discussion, updated);
  }

  async function saveNote(note, noteText) {
    const {
      data: { note: updatedNote },
    } = await axios.put(note.path, {
      rapid_diffs: true,
      target_id: note.noteable_id,
      note: { note: noteText },
    });
    diffDiscussions.updateNote(updatedNote);
  }

  async function destroyNote(note) {
    await axios.delete(note.path);
    diffDiscussions.deleteNote(note);
  }

  async function toggleAwardOnNote(note, name) {
    await axios.post(note.toggle_award_path, { name });
    diffDiscussions.toggleAward({ note, award: name });
  }

  function replyToLineDiscussion({ oldPath, newPath, lineRange }) {
    const { end } = lineRange;
    const singleLineRange = { start: end, end };
    const id = diffDiscussions.replyToLineDiscussion({
      oldPath,
      newPath,
      oldLine: end.old_line,
      newLine: end.new_line,
    });
    if (id) return id;
    return diffDiscussions.addNewLineDiscussionForm({
      oldPath,
      newPath,
      lineRange: singleLineRange,
    });
  }

  return {
    setDiscussionsEndpoint,
    createNewDiscussion,
    createLineDiscussion,
    replyToDiscussion,
    saveNote,
    destroyNote,
    toggleAwardOnNote,
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
    replyToLineDiscussion,
    addNewLineDiscussionForm: diffDiscussions.addNewLineDiscussionForm,
    replaceDiscussionForm: diffDiscussions.replaceDiscussionForm,
    removeNewLineDiscussionForm: diffDiscussions.removeNewLineDiscussionForm,
    setDiscussionFormText: diffDiscussions.setDiscussionFormText,
    setNewLineDiscussionFormAutofocus: diffDiscussions.setNewLineDiscussionFormAutofocus,
    setFileDiscussionsHidden: diffDiscussions.setFileDiscussionsHidden,
    setPositionDiscussionsHidden: diffDiscussions.setPositionDiscussionsHidden,
    discussionsWithForms: computed(() => diffDiscussions.discussionsWithForms),
    getImageDiscussions: computed(() => diffDiscussions.getImageDiscussions),
    findDiscussionsForPosition: computed(() => diffDiscussions.findDiscussionsForPosition),
    findDiscussionsForFile: computed(() => diffDiscussions.findDiscussionsForFile),
    findAllDiscussionsForFile: computed(() => diffDiscussions.findAllDiscussionsForFile),
    timelineDiscussions,
  };
});
