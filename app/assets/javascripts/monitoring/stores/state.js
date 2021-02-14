import invalidUrl from '~/lib/utils/invalid_url';
import { defaultTimeRange } from '~/vue_shared/constants';
import { dashboardEmptyStates } from '../constants';
import { timezones } from '../format_date';

export default () => ({
  // API endpoints
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  dashboardsEndpoint: invalidUrl,
  panelPreviewEndpoint: invalidUrl,

  // Dashboard request parameters
  timeRange: null,
  /**
   * Currently selected dashboard. For custom dashboards,
   * this could be the filename or the file path.
   *
   * If this is the filename and full path is required,
   * getters.fullDashboardPath should be used.
   */
  currentDashboard: null,

  // Dashboard data
  hasDashboardValidationWarnings: false,

  /**
   * {?String} If set, dashboard should display a global
   * empty state, there is no way to interact (yet)
   * with the dashboard.
   */
  emptyState: dashboardEmptyStates.GETTING_STARTED,
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
  variables: [],
  /**
   * User-defined custom links are passed
   * via the dashboard yml file.
   */
  links: [],

  // Panel editor / builder
  panelPreviewYml: '',
  panelPreviewIsLoading: false,
  panelPreviewGraphData: null,
  panelPreviewError: null,
  panelPreviewTimeRange: defaultTimeRange,
  panelPreviewIsShown: false,

  // Other project data
  dashboardTimezone: timezones.LOCAL,
  annotations: [],
  deploymentData: [],
  environments: [],
  environmentsSearchTerm: '',
  environmentsLoading: false,
  currentEnvironmentName: null,

  // GitLab paths to other pages
  externalDashboardUrl: '',
  projectPath: null,
  operationsSettingsPath: '',
  logsPath: invalidUrl,
  addDashboardDocumentationPath: '',

  // static paths
  customDashboardBasePath: '',

  // current user data
  /**
   * Flag that denotes if the currently logged user can access
   * the project Settings -> Operations
   */
  canAccessOperationsSettings: false,
});
