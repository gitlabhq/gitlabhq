import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  metricsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,

  dashboard: {
    panel_groups: [],
  },

  deploymentData: [],
  environments: [],
  environmentsSearchTerm: '',
  environmentsLoading: false,
  allDashboards: [],
  currentDashboard: null,
  projectPath: null,
});
