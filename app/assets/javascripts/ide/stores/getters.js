import { __ } from '~/locale';

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

// eslint-disable-next-line no-confusing-arrow
export const collapseButtonIcon = state =>
  state.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';

export const hasChanges = state => !!state.changedFiles.length || !!state.stagedFiles.length;

// eslint-disable-next-line no-confusing-arrow
export const collapseButtonTooltip = state =>
  state.rightPanelCollapsed ? __('Expand sidebar') : __('Collapse sidebar');

export const hasMergeRequest = state => !!state.currentMergeRequestId;

export const allBlobs = state =>
  Object.keys(state.entries)
    .reduce((acc, key) => {
      const entry = state.entries[key];

      if (entry.type === 'blob') {
        acc.push(entry);
      }

      return acc;
    }, [])
    .sort((a, b) => b.lastOpenedAt - a.lastOpenedAt);

export const getStagedFile = state => path => state.stagedFiles.find(f => f.path === path);
