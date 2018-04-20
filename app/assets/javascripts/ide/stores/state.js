export const ActivityBarViews = {
  edit: 'ide-tree',
  commit: 'commit-section',
};

export default () => ({
  currentProjectId: '',
  currentBranchId: '',
  currentMergeRequestId: '',
  changedFiles: [],
  stagedFiles: [],
  endpoints: {},
  lastCommitMsg: '',
  lastCommitPath: '',
  loading: false,
  openFiles: [],
  parentTreeUrl: '',
  trees: {},
  projects: {},
  leftPanelCollapsed: false,
  rightPanelCollapsed: false,
  panelResizing: false,
  entries: {},
  viewer: 'editor',
  delayViewerUpdated: false,
  currentActivityView: ActivityBarViews.edit,
});
