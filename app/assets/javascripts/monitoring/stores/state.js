import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  metricsEndpoint: null,
  environmentsEndpoint: null,
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
  metricsWithData: [],
  allDashboards: [],
  currentDashboard: null,
  projectPath: null,
});
