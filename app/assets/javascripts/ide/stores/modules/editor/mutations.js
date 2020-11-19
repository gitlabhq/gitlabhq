import Vue from 'vue';
import * as types from './mutation_types';
import { getFileEditorOrDefault } from './utils';

export default {
  [types.UPDATE_FILE_EDITOR](state, { path, data }) {
    const editor = getFileEditorOrDefault(state.fileEditors, path);

    Vue.set(state.fileEditors, path, Object.assign(editor, data));
  },
  [types.REMOVE_FILE_EDITOR](state, path) {
    Vue.delete(state.fileEditors, path);
  },
  [types.RENAME_FILE_EDITOR](state, { path, newPath }) {
    const existing = state.fileEditors[path];

    // Gracefully do nothing if fileEditor isn't found.
    if (!existing) {
      return;
    }

    Vue.delete(state.fileEditors, path);
    Vue.set(state.fileEditors, newPath, existing);
  },
};
