import * as types from './mutation_types';
import { getFileEditorOrDefault } from './utils';

const deletePropertyAndReturnNewCopy = (source, property) => {
  const fileEditorsCopy = { ...source };
  delete fileEditorsCopy[property];

  return fileEditorsCopy;
};

export default {
  [types.UPDATE_FILE_EDITOR](state, { path, data }) {
    const editor = getFileEditorOrDefault(state.fileEditors, path);

    state.fileEditors = {
      ...state.fileEditors,
      [path]: Object.assign(editor, data),
    };
  },
  [types.REMOVE_FILE_EDITOR](state, path) {
    state.fileEditors = deletePropertyAndReturnNewCopy(state.fileEditors, path);
  },
  [types.RENAME_FILE_EDITOR](state, { path, newPath }) {
    const existing = state.fileEditors[path];

    // Gracefully do nothing if fileEditor isn't found.
    if (!existing) {
      return;
    }

    state.fileEditors = deletePropertyAndReturnNewCopy(state.fileEditors, path);

    state.fileEditors = {
      ...state.fileEditors,
      [newPath]: existing,
    };
  },
};
