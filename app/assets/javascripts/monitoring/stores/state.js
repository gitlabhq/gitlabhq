import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  // API endpoints
  metricsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,

  // Dashboard request parameters
  timeRange: null,
  currentDashboard: null,

  // Dashboard data
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,
  dashboard: {
    panelGroups: [],
  },
  allDashboards: [],

  // Other project data
  annotations: [],
  deploymentData: [],
  environments: [],
  environmentsSearchTerm: '',
  environmentsLoading: false,

  // GitLab paths to other pages
  projectPath: null,
  logsPath: invalidUrl,
});
