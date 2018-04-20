import { ActivityBarViews } from '../constants';

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
