import { getFileEditorOrDefault } from './utils';

export const activeFileEditor = (state, getters, rootState, rootGetters) => {
  const { activeFile } = rootGetters;

  if (!activeFile) {
    return null;
  }

  const { path } = rootGetters.activeFile;

  return getFileEditorOrDefault(state.fileEditors, path);
};
