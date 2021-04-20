import { s__ } from '~/locale';
import { CONFLICT_TYPES, EDIT_RESOLVE_MODE, INTERACTIVE_RESOLVE_MODE } from '../constants';

export const getConflictsCount = (state) => {
  if (!state.conflictsData.files.length) {
    return 0;
  }

  const { files } = state.conflictsData;
  let count = 0;

  files.forEach((file) => {
    if (file.type === CONFLICT_TYPES.TEXT) {
      file.sections.forEach((section) => {
        if (section.conflict) {
          count += 1;
        }
      });
    } else {
      count += 1;
    }
  });

  return count;
};

export const getConflictsCountText = (state, getters) => {
  const count = getters.getConflictsCount;
  const text = count > 1 ? s__('MergeConflict|conflicts') : s__('MergeConflict|conflict');

  return `${count} ${text}`;
};

export const isReadyToCommit = (state) => {
  const { files } = state.conflictsData;
  const hasCommitMessage = state.conflictsData.commitMessage.trim().length;
  let unresolved = 0;

  for (let i = 0, l = files.length; i < l; i += 1) {
    const file = files[i];

    if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
      let numberConflicts = 0;
      const resolvedConflicts = Object.keys(file.resolutionData).length;

      // We only check for conflicts type 'text'
      // since conflicts `text_editor` can´t be resolved in interactive mode
      if (file.type === CONFLICT_TYPES.TEXT) {
        for (let j = 0, k = file.sections.length; j < k; j += 1) {
          if (file.sections[j].conflict) {
            numberConflicts += 1;
          }
        }

        if (resolvedConflicts !== numberConflicts) {
          unresolved += 1;
        }
      }
    } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
      // Unlikely to happen since switching to Edit mode saves content automatically.
      // Checking anyway in case the save strategy changes in the future
      if (!file.content) {
        unresolved += 1;
        // eslint-disable-next-line no-continue
        continue;
      }
    }
  }

  return Boolean(!state.isSubmitting && hasCommitMessage && !unresolved);
};

export const getCommitButtonText = (state) => {
  const initial = s__('MergeConflict|Commit to source branch');
  const inProgress = s__('MergeConflict|Committing...');

  return state.isSubmitting ? inProgress : initial;
};

export const getCommitData = (state) => {
  let commitData = {};

  commitData = {
    commit_message: state.conflictsData.commitMessage,
    files: [],
  };

  state.conflictsData.files.forEach((file) => {
    const addFile = {
      old_path: file.old_path,
      new_path: file.new_path,
    };

    if (file.type === CONFLICT_TYPES.TEXT) {
      // Submit only one data for type of editing
      if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
        addFile.sections = file.resolutionData;
      } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
        addFile.content = file.content;
      }
    } else if (file.type === CONFLICT_TYPES.TEXT_EDITOR) {
      addFile.content = file.content;
    }

    commitData.files.push(addFile);
  });

  return commitData;
};

export const fileTextTypePresent = (state) => {
  return state.conflictsData?.files.some((f) => f.type === CONFLICT_TYPES.TEXT);
};

export const getFileIndex = (state) => ({ blobPath }) => {
  return state.conflictsData.files.findIndex((f) => f.blobPath === blobPath);
};
