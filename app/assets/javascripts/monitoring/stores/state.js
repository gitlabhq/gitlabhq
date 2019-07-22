import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  hasMetrics: false,
  showPanels: true,
  metricsEndpoint: null,
  environmentsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  useDashboardEndpoint: false,
  multipleDashboardsEnabled: false,
  additionalPanelTypesEnabled: false,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,
  groups: [],
  deploymentData: [],
  environments: [],
  metricsWithData: [],
  allDashboards: [],
  currentDashboard: null,
  projectPath: null,
});
