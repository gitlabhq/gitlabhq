export const EDITOR_APP_DRAWER_HELP = 'HELP';
export const EDITOR_APP_DRAWER_JOB_ASSISTANT = 'JOB_ASSISTANT';
export const EDITOR_APP_DRAWER_AI_ASSISTANT = 'AI_ASSISTANT';
export const EDITOR_APP_DRAWER_NONE = '';

// Values for CI_CONFIG_STATUS_* comes from lint graphQL
export const CI_CONFIG_STATUS_INVALID = 'INVALID';
export const CI_CONFIG_STATUS_VALID = 'VALID';

// Values for EDITOR_APP_STATUS_* are frontend specifics and
// represent the global state of the pipeline editor app.
export const EDITOR_APP_STATUS_EMPTY = 'EMPTY';
export const EDITOR_APP_STATUS_INVALID = CI_CONFIG_STATUS_INVALID;
export const EDITOR_APP_STATUS_LINT_UNAVAILABLE = 'LINT_DOWN';
export const EDITOR_APP_STATUS_LOADING = 'LOADING';
export const EDITOR_APP_STATUS_VALID = CI_CONFIG_STATUS_VALID;

export const EDITOR_APP_VALID_STATUSES = [
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_LINT_UNAVAILABLE,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
];

export const COMMIT_FAILURE = 'COMMIT_FAILURE';
export const COMMIT_SUCCESS = 'COMMIT_SUCCESS';
export const COMMIT_SUCCESS_WITH_REDIRECT = 'COMMIT_SUCCESS_WITH_REDIRECT';

export const DEFAULT_FAILURE = 'DEFAULT_FAILURE';
export const DEFAULT_SUCCESS = 'DEFAULT_SUCCESS';
export const LOAD_FAILURE_UNKNOWN = 'LOAD_FAILURE_UNKNOWN';
export const PIPELINE_FAILURE = 'PIPELINE_FAILURE';

export const CREATE_TAB = 'CREATE_TAB';
export const MERGED_TAB = 'MERGED_TAB';
export const VALIDATE_TAB = 'VALIDATE_TAB';
export const VISUALIZE_TAB = 'VISUALIZE_TAB';

export const TABS_INDEX = {
  [CREATE_TAB]: '0',
  [VISUALIZE_TAB]: '1',
  [VALIDATE_TAB]: '2',
  [MERGED_TAB]: '3',
};
export const TAB_QUERY_PARAM = 'tab';

export const COMMIT_ACTION_CREATE = 'CREATE';
export const COMMIT_ACTION_UPDATE = 'UPDATE';

export const BRANCH_PAGINATION_LIMIT = 20;
export const BRANCH_SEARCH_DEBOUNCE = '500';
export const SOURCE_EDITOR_DEBOUNCE = 500;

export const FILE_TREE_DISPLAY_KEY = 'pipeline_editor_file_tree_display';
export const FILE_TREE_POPOVER_DISMISSED_KEY = 'pipeline_editor_file_tree_popover_dismissed';
export const FILE_TREE_TIP_DISMISSED_KEY = 'pipeline_editor_file_tree_tip_dismissed';
export const VALIDATE_TAB_BADGE_DISMISSED_KEY = 'pipeline_editor_validate_tab_badge_dismissed';

export const STARTER_TEMPLATE_NAME = 'Getting-Started';

export const CI_EXAMPLES_LINK = 'CI_EXAMPLES_LINK';
export const CI_HELP_LINK = 'CI_HELP_LINK';
export const CI_NEEDS_LINK = 'CI_NEEDS_LINK';
export const CI_RUNNERS_LINK = 'CI_RUNNERS_LINK';
export const CI_YAML_LINK = 'CI_YAML_LINK';
export const GITLAB_UNIVERSITY_LINK = 'GITLAB_UNIVERSITY_LINK';

export const pipelineEditorTrackingOptions = {
  label: 'pipeline_editor',
  actions: {
    browseCatalog: 'browse_catalog',
    browseTemplates: 'browse_templates',
    closeHelpDrawer: 'close_help_drawer',
    commitCiConfig: 'commit_ci_config',
    helpDrawerLinks: {
      [CI_EXAMPLES_LINK]: 'visit_help_drawer_link_ci_examples',
      [CI_HELP_LINK]: 'visit_help_drawer_link_ci_help',
      [CI_NEEDS_LINK]: 'visit_help_drawer_link_needs',
      [CI_RUNNERS_LINK]: 'visit_help_drawer_link_runners',
      [CI_YAML_LINK]: 'visit_help_drawer_link_yaml',
      [GITLAB_UNIVERSITY_LINK]: 'visit_help_drawer_link_gitlab_university',
    },
    openHelpDrawer: 'open_help_drawer',
    resimulatePipeline: 'resimulate_pipeline',
    simulatePipeline: 'simulate_pipeline',
  },
};

export const VALIDATE_TAB_FEEDBACK_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/346687';

export const COMMIT_SHA_POLL_INTERVAL = 1000;
export const PIPELINE_POLL_INTERVAL = 5000;
