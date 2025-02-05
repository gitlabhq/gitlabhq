import { __, s__ } from '~/locale';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';

export const RUNNER_TYPENAME = 'CiRunner'; // __typename

export const RUNNER_PAGE_SIZE = 20;
export const RUNNER_JOB_COUNT_LIMIT = 1000;

export const RUNNER_DETAILS_PROJECTS_PAGE_SIZE = 5;
export const RUNNER_DETAILS_JOBS_PAGE_SIZE = 30;

export const I18N_FETCH_ERROR = s__('Runners|Something went wrong while fetching runner data.');
export const I18N_CREATE_ERROR = s__(
  'Runners|An error occurred while creating the runner. Please try again.',
);

export const FILTER_CSS_CLASSES =
  'gl-bg-subtle gl-p-5 gl-border-solid gl-border-default gl-border-0 gl-border-t-1';

// Type

export const I18N_ALL_TYPES = s__('Runners|All');
export const I18N_INSTANCE_TYPE = s__('Runners|Instance');
export const I18N_GROUP_TYPE = s__('Runners|Group');
export const I18N_PROJECT_TYPE = s__('Runners|Project');
export const I18N_INSTANCE_RUNNER_DESCRIPTION = s__('Runners|Available to all projects');
export const I18N_GROUP_RUNNER_DESCRIPTION = s__(
  'Runners|Available to all projects and subgroups in the group',
);
export const I18N_PROJECT_RUNNER_DESCRIPTION = s__('Runners|Associated with one or more projects');

// Status
export const I18N_STATUS_ONLINE = s__('Runners|Online');
export const I18N_STATUS_NEVER_CONTACTED = s__('Runners|Never contacted');
export const I18N_STATUS_OFFLINE = s__('Runners|Offline');
export const I18N_STATUS_STALE = s__('Runners|Stale');

// Executor Status
export const I18N_JOB_STATUS_ACTIVE = s__('Runners|Active');
export const I18N_JOB_STATUS_IDLE = s__('Runners|Idle');

// Status tooltips
export const I18N_ONLINE_TOOLTIP = s__('Runners|Last contact was %{timeAgo}');
export const I18N_NEVER_CONTACTED_TOOLTIP = s__('Runners|Runner has never contacted this instance');
export const I18N_NEVER_CONTACTED_STALE_TOOLTIP = s__(
  'Runners|Runner is older than %{elapsedTime} and has never contacted GitLab',
);
export const I18N_DISCONNECTED_TOOLTIP = s__(
  "Runners|Runner hasn't contacted GitLab in more than %{elapsedTime} and last contact was %{timeAgo}",
);

// Default online/stale status timeouts, actual values
export const ONLINE_CONTACT_TIMEOUT_SECS = 2 * 60 * 60; // 2 hours
export const STALE_TIMEOUT_SECS = 604800; // 7.days

// Registration dropdown
export const I18N_REGISTER_INSTANCE_TYPE = s__('Runners|Register an instance runner');
export const I18N_REGISTER_GROUP_TYPE = s__('Runners|Register a group runner');
export const I18N_REGISTER_PROJECT_TYPE = s__('Runners|Register a project runner');
export const I18N_REGISTER_RUNNER = s__('Runners|Register a runner');

// Actions
export const I18N_EDIT = __('Edit');

export const I18N_PAUSE = __('Pause');
export const I18N_PAUSED = s__('Runners|Paused');
export const I18N_PAUSE_TOOLTIP = s__('Runners|Pause from accepting jobs');
export const I18N_PAUSED_DESCRIPTION = s__('Runners|Not accepting jobs');

export const I18N_RESUME = __('Resume');
export const I18N_RESUME_TOOLTIP = s__('Runners|Resume accepting jobs');

export const I18N_DELETE = s__('Runners|Delete');
export const I18N_DELETE_RUNNER = s__('Runners|Delete runner');
export const I18N_DELETED_TOAST = s__('Runners|Runner %{name} was deleted');

// List
export const I18N_CREATOR = s__('Runners|Creator');
export const I18N_LOCKED_RUNNER_DESCRIPTION = s__(
  'Runners|Runner is locked and available for currently assigned projects only. Only administrators can change the assigned projects.',
);
export const I18N_VERSION = s__('Runners|Version starts with');
export const I18N_VERSION_LABEL = s__('Runners|Version %{version}');
export const I18N_LAST_CONTACT_LABEL = s__('Runners|Last contact: %{timeAgo}');

export const I18N_CREATED_AT_LABEL = s__('Runners|Created %{timeAgo}');
export const I18N_CREATED_BY_LABEL = s__('Runners|Created by %{user}');
export const I18N_CREATED_BY_AT_LABEL = s__('Runners|Created by %{user} %{timeAgo}');

export const I18N_SHOW_ONLY_INHERITED = s__('Runners|Show only inherited');
export const I18N_ADMIN = s__('Runners|Administrator');

// No runners registered
export const I18N_GET_STARTED = s__('Runners|Get started with runners');
export const I18N_RUNNERS_ARE_AGENTS = s__(
  'Runners|Runners are the agents that run your CI/CD jobs.',
);
export const I18N_CREATE_RUNNER_LINK = s__(
  'Runners|%{linkStart}Create a new runner%{linkEnd} to get started.',
);
export const I18N_STILL_USING_REGISTRATION_TOKENS = s__('Runners|Still using registration tokens?');
export const I18N_CONTACT_ADMIN_TO_REGISTER = s__(
  'Runners|To register new runners, contact your administrator.',
);

// Runner details

export const JOBS_ROUTE_PATH = '/jobs'; // vue-router route path

export const I18N_DETAILS = s__('Runners|Details');
export const I18N_JOBS = s__('Runners|Jobs');
export const I18N_ASSIGNED_PROJECTS = s__('Runners|Assigned Projects (%{projectCount})');
export const I18N_FILTER_PROJECTS = s__('Runners|Filter projects');
export const I18N_CLEAR_FILTER_PROJECTS = __('Clear');
export const I18N_NO_JOBS_FOUND = s__('Runners|This runner has not run any jobs.');
export const I18N_NO_PROJECTS_FOUND = __('No projects found');

// Runner registration

export const RUNNER_REGISTRATION_POLLING_INTERVAL_MS = 2000;

// Styles

export const RUNNER_TAG_BADGE_VARIANT = 'info';
export const RUNNER_TAG_BG_CLASS = 'gl-bg-blue-100';

// Filtered search parameter names
// - Used for URL params names
// - GlFilteredSearch tokens type

export const PARAM_KEY_CREATOR = 'creator';
export const PARAM_KEY_STATUS = 'status';
export const PARAM_KEY_PAUSED = 'paused';
export const PARAM_KEY_RUNNER_TYPE = 'runner_type';
export const PARAM_KEY_TAG = 'tag';
export const PARAM_KEY_VERSION = 'version_prefix';
export const PARAM_KEY_SEARCH = 'search';
export const PARAM_KEY_MEMBERSHIP = 'membership';

export const PARAM_KEY_SORT = 'sort';
export const PARAM_KEY_AFTER = 'after';
export const PARAM_KEY_BEFORE = 'before';

export const PARAM_KEY_PLATFORM = 'platform';

// CiRunnerType

export const INSTANCE_TYPE = 'INSTANCE_TYPE';
export const GROUP_TYPE = 'GROUP_TYPE';
export const PROJECT_TYPE = 'PROJECT_TYPE';
export const RUNNER_TYPES = [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE];

// CiRunnerStatus

export const STATUS_ONLINE = 'ONLINE';
export const STATUS_NEVER_CONTACTED = 'NEVER_CONTACTED';
export const STATUS_OFFLINE = 'OFFLINE';
export const STATUS_STALE = 'STALE';

// CiRunnerJobExecutionStatus

export const JOB_STATUS_ACTIVE = 'ACTIVE';
export const JOB_STATUS_IDLE = 'IDLE';

// CiRunnerAccessLevel

export const ACCESS_LEVEL_NOT_PROTECTED = 'NOT_PROTECTED';
export const ACCESS_LEVEL_REF_PROTECTED = 'REF_PROTECTED';

export const DEFAULT_ACCESS_LEVEL = ACCESS_LEVEL_NOT_PROTECTED;

// CiRunnerSort

export const CREATED_DESC = 'CREATED_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CONTACTED_DESC = 'CONTACTED_DESC';
export const CONTACTED_ASC = 'CONTACTED_ASC';

export const DEFAULT_SORT = CREATED_DESC;

// CiRunnerMembershipFilter

export const MEMBERSHIP_DESCENDANTS = 'DESCENDANTS';
export const MEMBERSHIP_ALL_AVAILABLE = 'ALL_AVAILABLE';

export const DEFAULT_MEMBERSHIP = MEMBERSHIP_DESCENDANTS;

// Local storage namespaces

export const ADMIN_FILTERED_SEARCH_NAMESPACE = 'admin_runners';
export const GROUP_FILTERED_SEARCH_NAMESPACE = 'group_runners';

// Platforms

export const LINUX_PLATFORM = 'linux';
export const MACOS_PLATFORM = 'osx';
export const WINDOWS_PLATFORM = 'windows';
export const GOOGLE_CLOUD_PLATFORM = 'google_cloud';
export const GOOGLE_KUBERNETES_ENGINE = 'gke';

// Stages for the google cloud setup
export const GOOGLE_CLOUD_SETUP_START = 'google_cloud_setup_start';
export const GOOGLE_CLOUD_SETUP_END = 'google_cloud_setup_end';

// About Gitlab Runner Package host
export const RUNNER_PACKAGE_HOST = 'gitlab-runner-downloads.s3.amazonaws.com';

export const DEFAULT_PLATFORM = LINUX_PLATFORM;

// Runner docs are in a separate repository and are not shipped with GitLab
// they are rendered as external URLs.
export const INSTALL_HELP_URL = `${DOCS_URL}/runner/install`;
export const EXECUTORS_HELP_URL = `${DOCS_URL}/runner/executors/`;
export const SERVICE_COMMANDS_HELP_URL = `${DOCS_URL}/runner/commands/#service-related-commands`;
export const CHANGELOG_URL = `https://gitlab.com/gitlab-org/gitlab-runner/blob/main/CHANGELOG.md`;
export const DOCKER_HELP_URL = `${DOCS_URL}/runner/install/docker.html`;
export const KUBERNETES_HELP_URL = `${DOCS_URL}/runner/install/kubernetes.html`;
export const RUNNER_MANAGERS_HELP_URL = `${DOCS_URL}/runner/fleet_scaling/#workers-executors-and-autoscaling-capabilities`;
export const SINGLE_RUNNER_ENTRY_HELP_URL = `${DOCS_URL}/runner/configuration/advanced-configuration#the-runners-section`;
