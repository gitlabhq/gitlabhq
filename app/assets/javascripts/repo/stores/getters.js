import _ from 'underscore';

export const treeList = (state) => {
  const mapTree = arr => (!arr.tree.length ? [] : _.map(arr.tree, a => [a, mapTree(a)]));

  return _.chain(state.tree)
    .map(arr => [arr, mapTree(arr)])
    .flatten()
    .value();
};

export const changedFiles = (state) => {
  const files = state.openFiles;

  return files.filter(file => file.changed);
};

export const activeFile = state => state.openFiles.find(file => file.active);

export const activeFileExtension = (state) => {
  const file = activeFile(state);
  return file ? `.${file.path.split('.').pop()}` : '';
};

export const isMini = state => !!state.openFiles.length;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);
  const openedFiles = state.openFiles;

  return state.canCommit &&
    state.onTopOfBranch &&
    openedFiles.length &&
    (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};
