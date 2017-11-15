import _ from 'underscore';

const DEFAULT_VIEWER = 'html';

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

  if (!file) return null;

  return file[file.currentViewer];
};

export const canActiveFileSwitchViewer = (state) => {
  const file = activeFile(state);

  if (!file) return false;
  if (file.binary) return false;

  return file.rich.path !== '' && file.simple.path !== '' && file.simple.name === 'text';
};

export const isCollapsed = state => !!state.openFiles.length;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);
  const openedFiles = state.openFiles;

  return state.canCommit &&
    state.onTopOfBranch &&
    openedFiles.length &&
    (currentActiveFile && !currentActiveFile.binary);
};

export const viewerTemplateName = (state) => {
  const viewer = activeFileCurrentViewer(state);

  if (!viewer) return null;

  if (viewer.renderError) {
    return 'error';
  }

  switch (viewer.name) {
    default:
      return DEFAULT_VIEWER;
  }
};

export const canRenderLocally = (state) => {
  const viewer = activeFileCurrentViewer(state);
  const viewerTemplate = viewerTemplateName(state);

  if (viewerTemplate !== DEFAULT_VIEWER || (viewer && viewer.html !== '')) {
    return true;
  }

  return false;
};
