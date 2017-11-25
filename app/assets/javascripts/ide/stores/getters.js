import _ from 'underscore';

/*
  Takes the multi-dimensional tree and returns a flattened array.
  This allows for the table to recursively render the table rows but keeps the data
  structure nested to make it easier to add new files/directories.
*/
export const treeList = state => (treeId) => {
  if (state.trees[treeId]) {
    const mapTree = arr => (!arr.tree || !arr.tree.length ? [] : _.map(arr.tree, a => [a, mapTree(a)]));

    return _.chain(state.trees[treeId].tree)
      .map(arr => [arr, mapTree(arr)])
      .flatten()
      .value();
  }
  return [];
};

export const getFile = state => (treeId) => {
  const fileList = treeList(state, treeId);
  console.log('Files ', fileList);
  // debugger;
};

export const changedFiles = state => state.openFiles.filter(file => file.changed);

export const activeFile = state => state.openFiles.find(file => file.active) || null;

export const activeFileExtension = (state) => {
  const file = activeFile(state);
  return file ? `.${file.path.split('.').pop()}` : '';
};

export const isCollapsed = state => !!state.openFiles.length;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);
  const openedFiles = state.openFiles;

  return true;

  return state.canCommit &&
    state.onTopOfBranch &&
    openedFiles.length &&
    (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};

export const addedFiles = state => changedFiles(state).filter(f => f.tempFile);

export const modifiedFiles = state => changedFiles(state).filter(f => !f.tempFile);
