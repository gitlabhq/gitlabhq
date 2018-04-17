import { ActivityBarViews } from './state';

export const activeFile = state => state.openFiles.find(file => file.active) || null;

export const addedFiles = state => state.changedFiles.filter(f => f.tempFile);

export const modifiedFiles = state => state.changedFiles.filter(f => !f.tempFile);

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

export const currentMergeRequest = state => {
  if (state.projects[state.currentProjectId]) {
    return state.projects[state.currentProjectId].mergeRequests[state.currentMergeRequestId];
  }
  return null;
};

export const currentProject = state => state.projects[state.currentProjectId];

export const currentTree = state =>
  state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

// eslint-disable-next-line no-confusing-arrow
export const currentIcon = state =>
  state.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';

export const hasChanges = state => !!state.changedFiles.length;

export const hasMergeRequest = state => !!state.currentMergeRequestId;

export const activityBarComponent = state => {
  switch (state.currentActivityView) {
    case ActivityBarViews.edit:
      return 'ide-tree';
    case ActivityBarViews.commit:
      return 'commit-section';
    default:
      return null;
  }
};
