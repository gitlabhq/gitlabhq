import { sortTree } from './utils';

export const openFilesMap = state => state.openFiles.map(path => state.entries[path]);
export const changedFilesMap = state => state.changedFiles.map(path => state.entries[path]);

export const activeFile = state => openFilesMap(state).find(file => file.active) || null;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);

  return state.canCommit &&
         (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};

export const addedFiles = state => changedFilesMap(state).filter(f => f.tempFile);

export const modifiedFiles = state => changedFilesMap(state).filter(f => !f.tempFile);

export const treeList = (state) => {
  const tree = state.trees['root/testing-123/master'];

  if (!tree) return [];

  const map = (arr) => {
    if (!arr.tree.length) return [];

    return sortTree(arr.tree.reduce((acc, key) => {
      const entity = state.entries[key];

      if (entity) {
        return acc.concat({
          ...entity,
          tree: map(entity),
        });
      }

      return acc;
    }, []));
  };

  return map(tree);
};
