import { __, s__ } from '~/locale';

export const RUNNER_TYPENAME = 'CiRunner'; // __typename

export const RUNNER_PAGE_SIZE = 20;
export const RUNNER_JOB_COUNT_LIMIT = 1000;

export const RUNNER_DETAILS_PROJECTS_PAGE_SIZE = 5;
export const RUNNER_DETAILS_JOBS_PAGE_SIZE = 30;

export const I18N_FETCH_ERROR = s__('Runners|Something went wrong while fetching runner data.');
export const I18N_DETAILS_TITLE = s__('Runners|Runner #%{runner_id}');

export const FILTER_CSS_CLASSES =
  'gl-bg-gray-10 gl-p-5 gl-border-solid gl-border-gray-100 gl-border-0 gl-border-t-1 gl-border-b-1';

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
export const I18N_JOB_STATUS_RUNNING = s__('Runners|Running');
export const I18N_JOB_STATUS_IDLE = s__('Runners|Idle');

// Status help popover
export const I18N_STATUS_POPOVER_TITLE = s__('Runners|Runner statuses');

export const I18N_STATUS_POPOVER_NEVER_CONTACTED = s__('Runners|Never contacted:');
export const I18N_STATUS_POPOVER_NEVER_CONTACTED_DESCRIPTION = s__(
  'Runners|Runner has never contacted GitLab (when you register a runner, use %{codeStart}gitlab-runner run%{codeEnd} to bring it online)',
);
export const I18N_STATUS_POPOVER_ONLINE = s__('Runners|Online:');
export const I18N_STATUS_POPOVER_ONLINE_DESCRIPTION = s__(
  'Runners|Runner has contacted GitLab within the last %{elapsedTime}',
);
export const I18N_STATUS_POPOVER_OFFLINE = s__('Runners|Offline:');
export const I18N_STATUS_POPOVER_OFFLINE_DESCRIPTION = s__(
  'Runners|Runner has not contacted GitLab in more than %{elapsedTime}',
);
export const I18N_STATUS_POPOVER_STALE = s__('Runners|Stale:');
export const I18N_STATUS_POPOVER_STALE_DESCRIPTION = s__(
  'Runners|Runner has not contacted GitLab in more than %{elapsedTime}',
);

// Status tooltips
export const I18N_ONLINE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is online; last contact was %{timeAgo}',
);
export const I18N_NEVER_CONTACTED_TOOLTIP = s__('Runners|Runner has never contacted this instance');
export const I18N_OFFLINE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is offline; last contact was %{timeAgo}',
);
export const I18N_STALE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is stale; last contact was %{timeAgo}',
);
export const I18N_STALE_NEVER_CONTACTED_TOOLTIP = s__(
  'Runners|Runner is stale; it has never contacted this instance',
);

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

export const I18N_DELETE_RUNNER = s__('Runners|Delete runner');
export const I18N_DELETED_TOAST = s__('Runners|Runner %{name} was deleted');

// List
export const I18N_NO_DESCRIPTION = s__('Runners|No description');
export const I18N_LOCKED_RUNNER_DESCRIPTION = s__(
  'Runners|Runner is locked and available for currently assigned projects only. Only administrators can change the assigned projects.',
);
export const I18N_VERSION_LABEL = s__('Runners|Version %{version}');
export const I18N_LAST_CONTACT_LABEL = s__('Runners|Last contact: %{timeAgo}');
export const I18N_CREATED_AT_LABEL = s__('Runners|Created %{timeAgo}');
export const I18N_CREATED_AT_BY_LABEL = s__('Runners|Created %{timeAgo} by %{avatar}');
export const I18N_SHOW_ONLY_INHERITED = s__('Runners|Show only inherited');
export const I18N_ADMIN = s__('Runners|Administrator');

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

export const I18N_REGISTRATION_SUCCESS = s__("Runners|You've created a new runner!");

export const RUNNER_REGISTRATION_POLLING_INTERVAL_MS = 2000;

// Styles

export const RUNNER_TAG_BADGE_VARIANT = 'info';
export const RUNNER_TAG_BG_CLASS = 'gl-bg-blue-100';

// Filtered search parameter names
// - Used for URL params names
// - GlFilteredSearch tokens type

export const PARAM_KEY_STATUS = 'status';
export const PARAM_KEY_PAUSED = 'paused';
export const PARAM_KEY_RUNNER_TYPE = 'runner_type';
export const PARAM_KEY_TAG = 'tag';
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

export const JOB_STATUS_RUNNING = 'RUNNING';
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
export const AWS_PLATFORM = 'aws';

export const DOWNLOAD_LOCATIONS = {
  [LINUX_PLATFORM]: [
    {
      arch: 'amd64',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64',
    },
    {
      arch: '386',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-386',
    },
    {
      arch: 'arm',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm',
    },
    {
      arch: 'arm64',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm64',
    },
  ],
  [MACOS_PLATFORM]: [
    {
      arch: 'amd64',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-darwin-amd64',
    },
    {
      arch: 'arm64',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-darwin-arm64',
    },
  ],
  [WINDOWS_PLATFORM]: [
    {
      arch: 'amd64',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe',
    },
    {
      arch: '386',
      url:
        'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-386.exe',
    },
  ],
};

export const DEFAULT_PLATFORM = LINUX_PLATFORM;

// Runner docs are in a separate repository and are not shipped with GitLab
// they are rendered as external URLs.
export const INSTALL_HELP_URL = 'https://docs.gitlab.com/runner/install';
export const EXECUTORS_HELP_URL = 'https://docs.gitlab.com/runner/executors/';
export const SERVICE_COMMANDS_HELP_URL =
  'https://docs.gitlab.com/runner/commands/#service-related-commands';
export const CHANGELOG_URL = 'https://gitlab.com/gitlab-org/gitlab-runner/blob/main/CHANGELOG.md';
export const DOCKER_HELP_URL = 'https://docs.gitlab.com/runner/install/docker.html';
export const KUBERNETES_HELP_URL = 'https://docs.gitlab.com/runner/install/kubernetes.html';
