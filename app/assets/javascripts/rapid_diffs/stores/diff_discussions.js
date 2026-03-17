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

  const isFileDiscussion = (discussion) =>
    discussion.position?.position_type === 'file' ||
    (discussion.isForm &&
      discussion.position?.old_line === null &&
      discussion.position?.new_line === null);

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
        .filter((discussion) => !discussion.hidden && !isFileDiscussion(discussion));
    };
  });

  const findFileDiscussionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return findAllDiscussionsForFile
        .value({ oldPath, newPath })
        .filter((discussion) => !discussion.hidden && isFileDiscussion(discussion));
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

  function setPositionDiscussionsHidden({ oldPath, newPath, oldLine, newLine }, newState) {
    discussions.discussions.forEach((discussion) => {
      if (
        discussion.diff_discussion &&
        discussion.position?.old_path === oldPath &&
        discussion.position?.new_path === newPath &&
        discussion.position?.old_line === oldLine &&
        discussion.position?.new_line === newLine
      ) {
        discussion.hidden = newState;
      }
    });
  }

  function addNewLineDiscussionForm({ oldPath, newPath, lineRange }) {
    const { old_line: oldLine, new_line: newLine } = lineRange.end;
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
        line_range: lineRange,
      },
      isForm: true,
      noteBody: '',
      shouldFocus: true,
    });
    setPositionDiscussionsHidden({ oldPath, newPath, oldLine, newLine }, false);
    return undefined;
  }

  function replyToLineDiscussion({ oldPath, newPath, oldLine, newLine }) {
    const [existingDiscussion] = findDiscussionsForPosition
      .value({ oldPath, newPath, oldLine, newLine })
      .filter((discussion) => !discussion.isForm);
    if (!existingDiscussion) return undefined;
    setPositionDiscussionsHidden({ oldPath, newPath, oldLine, newLine }, false);
    discussions.startReplying(existingDiscussion);
    return existingDiscussion.id;
  }

  function removeNewLineDiscussionForm(discussion) {
    discussionForms.value.splice(discussionForms.value.indexOf(discussion), 1);
  }

  function replaceDiscussionForm(oldDiscussion, newDiscussion) {
    removeNewLineDiscussionForm(oldDiscussion);
    discussions.addDiscussion(newDiscussion);
  }

  function setDiscussionFormText(discussion, text) {
    discussion.noteBody = text;
  }

  function setNewLineDiscussionFormAutofocus(discussion, value) {
    discussion.shouldFocus = value;
  }

  function addNewFileDiscussionForm({ oldPath, newPath }) {
    const id = [oldPath, newPath, 'file'].join('-');
    if (discussionForms.value.some((discussion) => discussion.id === id)) return id;
    discussionForms.value.push({
      id,
      diff_discussion: true,
      position: {
        position_type: 'file',
        old_path: oldPath,
        new_path: newPath,
        old_line: null,
        new_line: null,
      },
      isForm: true,
      noteBody: '',
      shouldFocus: true,
    });
    return undefined;
  }

  function removeNewFileDiscussionForm(discussion) {
    discussionForms.value.splice(discussionForms.value.indexOf(discussion), 1);
  }

  return {
    discussionForms,
    discussionsWithForms,
    getImageDiscussions,
    findDiscussionsForPosition,
    findDiscussionsForFile,
    findAllDiscussionsForFile,
    findVisibleDiscussionsForFile,
    findFileDiscussionsForFile,
    collapseDiscussion: discussions.collapseDiscussion,
    expandDiscussion: discussions.expandDiscussion,
    replyToLineDiscussion,
    addNewLineDiscussionForm,
    replaceDiscussionForm,
    removeNewLineDiscussionForm,
    setDiscussionFormText,
    setNewLineDiscussionFormAutofocus,
    addNewFileDiscussionForm,
    removeNewFileDiscussionForm,
    setFileDiscussionsHidden,
    setPositionDiscussionsHidden,
    setInitialDiscussions: discussions.setInitialDiscussions,
    replaceDiscussion: discussions.replaceDiscussion,
    updateDiscussion: discussions.updateDiscussion,
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
