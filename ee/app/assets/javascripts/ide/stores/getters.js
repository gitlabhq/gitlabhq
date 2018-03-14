export const activeFile = state => state.openFiles.find(file => file.active) || null;

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);

  return state.canCommit &&
         (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};

export const addedFiles = state => state.changedFiles.filter(f => f.tempFile);

export const modifiedFiles = state => state.changedFiles.filter(f => !f.tempFile);

export const treeList = (state) => {
  const tree = state.trees[`${state.currentProjectId}/master`];

  if (!tree) return [];

  return tree.tree;
};
