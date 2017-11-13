import _ from 'underscore';

/*
  Takes the multi-dimensional tree and returns a flattened array.
  This allows for the table to recursively render the table rows but keeps the data
  structure nested to make it easier to add new files/directories.
*/
export const treeList = (state) => {
  const mapTree = arr => (!arr.tree.length ? [] : _.map(arr.tree, a => [a, mapTree(a)]));

  return _.chain(state.tree)
    .map(arr => [arr, mapTree(arr)])
    .flatten()
    .value();
};

export const changedFiles = state => state.openFiles.filter(file => file.changed);

export const activeFile = state => state.openFiles.find(file => file.active);

export const activeFileCurrentViewer = (state) => {
  const file = activeFile(state);

  return file[file.currentViewer];
};

export const activeFileHTML = (state) => {
  const viewier = activeFileCurrentViewer(state);

  return viewier.html;
};

export const canActiveFileSwitchViewer = (state) => {
  const file = activeFile(state);

  if (file.binary) return false;

  return file.rich.path !== '' && file.simple.path !== '';
};

export const activeFileExtension = (state) => {
  const file = activeFile(state);
  return file ? `.${file.path.split('.').pop()}` : '';
};

export const isCollapsed = state => !!state.openFiles.length;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);
  const openedFiles = state.openFiles;

  return state.canCommit &&
    state.onTopOfBranch &&
    openedFiles.length &&
    (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};
