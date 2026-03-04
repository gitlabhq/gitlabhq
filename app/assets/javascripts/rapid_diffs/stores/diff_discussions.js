/* eslint-disable no-param-reassign */
import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { useDiscussions } from '~/notes/store/discussions';

export const useDiffDiscussions = defineStore('diffDiscussions', () => {
  const discussions = useDiscussions();
  const discussionForms = ref([]);

  const discussionsWithForms = computed(() => {
    return [...discussions.discussions, ...discussionForms.value];
  });

  const getImageDiscussions = computed(() => {
    return (oldPath, newPath) =>
      discussionsWithForms.value.filter((discussion) => {
        const position = discussion.notes[0].position || {};
        return (
          position.position_type === 'image' &&
          position.old_path === oldPath &&
          position.new_path === newPath
        );
      });
  });

  const findDiscussionsForPosition = computed(() => {
    return ({ oldPath, newPath, oldLine, newLine }) => {
      return discussionsWithForms.value.filter((discussion) => {
        return (
          discussion.diff_discussion &&
          discussion.position.old_path === oldPath &&
          discussion.position.new_path === newPath &&
          discussion.position.old_line === oldLine &&
          discussion.position.new_line === newLine
        );
      });
    };
  });

  const findAllDiscussionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return discussionsWithForms.value.filter((discussion) => {
        return (
          discussion.diff_discussion &&
          discussion.position?.old_path === oldPath &&
          discussion.position?.new_path === newPath
        );
      });
    };
  });

  const findVisibleDiscussionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return findAllDiscussionsForFile
        .value({ oldPath, newPath })
        .filter((discussion) => !discussion.hidden);
    };
  });

  const findDiscussionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return findAllDiscussionsForFile.value({ oldPath, newPath }).filter((discussion) => {
        return !discussion.isForm;
      });
    };
  });

  function setFileDiscussionsHidden(oldPath, newPath, newState) {
    discussions.discussions.forEach((discussion) => {
      if (
        discussion.diff_discussion &&
        discussion.position?.old_path === oldPath &&
        discussion.position?.new_path === newPath
      ) {
        discussion.hidden = newState;
      }
    });
  }

  function addNewLineDiscussionForm({ oldPath, newPath, oldLine, newLine }) {
    const id = [oldPath, newPath, oldLine, newLine].join('-');
    if (discussionForms.value.some((discussion) => discussion.id === id)) return id;
    discussionForms.value.push({
      id,
      diff_discussion: true,
      position: {
        old_path: oldPath,
        new_path: newPath,
        old_line: oldLine,
        new_line: newLine,
      },
      isForm: true,
      noteBody: '',
      shouldFocus: true,
    });
    setFileDiscussionsHidden(oldPath, newPath, false);
    return undefined;
  }

  function replyToLineDiscussion({ oldPath, newPath, oldLine, newLine }) {
    const [existingDiscussion] = findDiscussionsForPosition
      .value({ oldPath, newPath, oldLine, newLine })
      .filter((discussion) => !discussion.isForm);
    if (existingDiscussion) {
      discussions.startReplying(existingDiscussion);
      return existingDiscussion.id;
    }
    return addNewLineDiscussionForm({ oldPath, newPath, oldLine, newLine });
  }

  function removeNewLineDiscussionForm(discussion) {
    discussionForms.value.splice(discussionForms.value.indexOf(discussion), 1);
  }

  function replaceDiscussionForm(oldDiscussion, newDiscussion) {
    removeNewLineDiscussionForm(oldDiscussion);
    discussions.addDiscussion(newDiscussion);
  }

  function setNewLineDiscussionFormText(discussion, text) {
    discussion.noteBody = text;
  }

  function setNewLineDiscussionFormAutofocus(discussion, value) {
    discussion.shouldFocus = value;
  }

  return {
    discussionForms,
    discussionsWithForms,
    getImageDiscussions,
    findDiscussionsForPosition,
    findDiscussionsForFile,
    findAllDiscussionsForFile,
    findVisibleDiscussionsForFile,
    replyToLineDiscussion,
    addNewLineDiscussionForm,
    replaceDiscussionForm,
    removeNewLineDiscussionForm,
    setNewLineDiscussionFormText,
    setNewLineDiscussionFormAutofocus,
    setFileDiscussionsHidden,
    setInitialDiscussions: discussions.setInitialDiscussions,
    replaceDiscussion: discussions.replaceDiscussion,
    toggleDiscussionReplies: discussions.toggleDiscussionReplies,
    expandDiscussionReplies: discussions.expandDiscussionReplies,
    startReplying: discussions.startReplying,
    stopReplying: discussions.stopReplying,
    addNote: discussions.addNote,
    updateNote: discussions.updateNote,
    updateNoteTextById: discussions.updateNoteTextById,
    editNote: discussions.editNote,
    deleteNote: discussions.deleteNote,
    addDiscussion: discussions.addDiscussion,
    deleteDiscussion: discussions.deleteDiscussion,
    setEditingMode: discussions.setEditingMode,
    requestLastNoteEditing: discussions.requestLastNoteEditing,
    toggleAward: discussions.toggleAward,
  };
});
