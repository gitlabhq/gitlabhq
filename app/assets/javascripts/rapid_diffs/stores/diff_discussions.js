/* eslint-disable no-param-reassign */
import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { useDiscussions } from '~/notes/store/discussions';
import {
  isFileDiscussion,
  isImageDiscussion,
  isLineDiscussion,
  positionMatchesFilePath,
  positionMatchesLine,
} from '~/rapid_diffs/utils/discussion_position';

export const useDiffDiscussions = defineStore('diffDiscussions', () => {
  const discussions = useDiscussions();
  const discussionForms = ref([]);

  const discussionsWithForms = computed(() => {
    return [...discussions.discussions, ...discussionForms.value];
  });

  const findAllDiscussionsForFile = computed(() => {
    const items = discussionsWithForms.value;
    return ({ oldPath, newPath }) => {
      return items.filter((discussion) => {
        return (
          discussion.diff_discussion &&
          discussion.position &&
          positionMatchesFilePath(discussion.position, { oldPath, newPath })
        );
      });
    };
  });

  const findLinePositionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return findAllDiscussionsForFile
        .value({ oldPath, newPath })
        .filter(isLineDiscussion)
        .map((discussion) => discussion.position);
    };
  });

  const findLineDiscussionsForPosition = computed(() => {
    return ({ oldPath, newPath, oldLine, newLine }) => {
      return findAllDiscussionsForFile
        .value({ oldPath, newPath })
        .filter(
          (discussion) =>
            isLineDiscussion(discussion) &&
            positionMatchesLine(discussion.position, { oldPath, newPath, oldLine, newLine }),
        );
    };
  });

  const findAllFileDiscussionsForFile = computed(() => {
    return ({ oldPath, newPath }) => {
      return findAllDiscussionsForFile.value({ oldPath, newPath }).filter(isFileDiscussion);
    };
  });

  const findAllImageDiscussionsForFile = computed(() => {
    const items = discussionsWithForms.value;
    return (oldPath, newPath) =>
      items.filter(
        (discussion) =>
          isImageDiscussion(discussion) &&
          positionMatchesFilePath(discussion.position, { oldPath, newPath }),
      );
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
        discussion.position &&
        positionMatchesFilePath(discussion.position, { oldPath, newPath })
      ) {
        discussion.hidden = newState;
      }
    });
  }

  function setPositionDiscussionsHidden(linePos, newState) {
    discussions.discussions.forEach((discussion) => {
      if (
        discussion.diff_discussion &&
        discussion.position &&
        positionMatchesLine(discussion.position, linePos)
      ) {
        discussion.hidden = newState;
      }
    });
  }

  function addNewLineDiscussionForm({
    oldPath,
    newPath,
    lineRange,
    lineChange,
    lineCode,
    positionExtras,
    extraOptions = {},
  }) {
    const { old_line: oldLine, new_line: newLine } = lineRange.end;
    const id = [oldPath, newPath, oldLine, newLine].join('-');
    if (discussionForms.value.some((discussion) => discussion.id === id)) return id;
    const position = {
      old_path: oldPath,
      new_path: newPath,
      old_line: oldLine,
      new_line: newLine,
      position_type: 'text',
      line_range: lineRange,
      ...positionExtras,
    };
    discussionForms.value.push({
      id,
      diff_discussion: true,
      position,
      original_position: position,
      lineChange,
      lineCode,
      ...extraOptions,
      isForm: true,
      noteBody: '',
      shouldFocus: true,
    });
    setPositionDiscussionsHidden({ oldPath, newPath, oldLine, newLine }, false);
    return undefined;
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

  const allDiffDiscussionsExpanded = computed(() => {
    return discussions.discussions
      .filter((discussion) => discussion.diff_discussion)
      .every((discussion) => !discussion.hidden);
  });

  function toggleAllDiffDiscussions() {
    const newHidden = allDiffDiscussionsExpanded.value;
    discussions.discussions.forEach((discussion) => {
      if (discussion.diff_discussion) {
        discussion.hidden = newHidden;
      }
    });
  }

  function expandFileDiscussions(oldPath, newPath) {
    discussions.discussions.forEach((discussion) => {
      if (
        discussion.diff_discussion &&
        discussion.position &&
        positionMatchesFilePath(discussion.position, { oldPath, newPath }) &&
        isFileDiscussion(discussion)
      ) {
        discussion.hidden = false;
      }
    });
  }

  function addNewFileDiscussionForm({ oldPath, newPath, positionExtras, extraOptions = {} }) {
    const id = [oldPath, newPath, 'file'].join('-');
    if (discussionForms.value.some((discussion) => discussion.id === id)) return id;
    const position = {
      position_type: 'file',
      old_path: oldPath,
      new_path: newPath,
      old_line: null,
      new_line: null,
      ...positionExtras,
    };
    discussionForms.value.push({
      id,
      diff_discussion: true,
      position,
      original_position: position,
      ...extraOptions,
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
    findDiscussionsForFile,
    findAllDiscussionsForFile,
    findLinePositionsForFile,
    findLineDiscussionsForPosition,
    findAllFileDiscussionsForFile,
    findAllImageDiscussionsForFile,
    collapseDiscussion: discussions.collapseDiscussion,
    expandDiscussion: discussions.expandDiscussion,
    allDiffDiscussionsExpanded,
    toggleAllDiffDiscussions,
    addNewLineDiscussionForm,
    replaceDiscussionForm,
    removeNewLineDiscussionForm,
    setDiscussionFormText,
    setNewLineDiscussionFormAutofocus,
    addNewFileDiscussionForm,
    removeNewFileDiscussionForm,
    expandFileDiscussions,
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
