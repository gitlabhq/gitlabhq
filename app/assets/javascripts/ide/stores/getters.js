export const activeFile = state =>
  state.openFiles.find(file => file.active) || null;

export const addedFiles = state => state.changedFiles.filter(f => f.tempFile);

export const modifiedFiles = state =>
  state.changedFiles.filter(f => !f.tempFile);

export const projectsWithTrees = state =>
  Object.keys(state.projects).map(projectId => {
    const project = state.projects[projectId];

    return {
      ...project,
      branches: Object.keys(project.branches).map(branchId => {
        const branch = project.branches[branchId];

        return {
          ...branch,
          tree: state.trees[branch.treeId],
        };
      }),
    };
  });

// eslint-disable-next-line no-confusing-arrow
export const currentIcon = state =>
  state.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';

export const hasChanges = state => !!state.changedFiles.length;

export const unstagedFiles = state => state.changedFiles.filter(f => !f.staged);
