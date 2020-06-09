import invalidUrl from '~/lib/utils/invalid_url';
import { timezones } from '../format_date';

export default () => ({
  // API endpoints
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  dashboardsEndpoint: invalidUrl,

  // Dashboard request parameters
  timeRange: null,
  currentDashboard: null,

  // Dashboard data
  emptyState: 'gettingStarted',
  showEmptyState: true,
  showErrorBanner: true,
  isUpdatingStarredValue: false,
  dashboard: {
    panelGroups: [],
  },
  /**
   * Panel that is currently "zoomed" in as
   * a single panel in view.
   */
  expandedPanel: {
    /**
     * {?String} Panel's group name.
     */
    group: null,
    /**
     * {?Object} Panel content from `dashboard`
     * null when no panel is expanded.
     */
    panel: null,
  },
  allDashboards: [],
  /**
   * User-defined custom variables are passed
   * via the dashboard yml file.
   */
  variables: {},
  /**
   * User-defined custom links are passed
   * via the dashboard yml file.
   */
  links: [],
  // Other project data
  dashboardTimezone: timezones.LOCAL,
  annotations: [],
  deploymentData: [],
  environments: [],
  environmentsSearchTerm: '',
  environmentsLoading: false,
  currentEnvironmentName: null,

  // GitLab paths to other pages
  projectPath: null,
  logsPath: invalidUrl,
});
