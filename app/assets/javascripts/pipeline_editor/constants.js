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
export const LINT_TAB = 'LINT_TAB';
export const MERGED_TAB = 'MERGED_TAB';
export const VISUALIZE_TAB = 'VISUALIZE_TAB';

export const TABS_INDEX = {
  [CREATE_TAB]: '0',
  [VISUALIZE_TAB]: '1',
  [LINT_TAB]: '2',
  [MERGED_TAB]: '3',
};
export const TAB_QUERY_PARAM = 'tab';

export const COMMIT_ACTION_CREATE = 'CREATE';
export const COMMIT_ACTION_UPDATE = 'UPDATE';

export const DRAWER_EXPANDED_KEY = 'pipeline_editor_drawer_expanded';

export const BRANCH_PAGINATION_LIMIT = 20;
export const BRANCH_SEARCH_DEBOUNCE = '500';
export const SOURCE_EDITOR_DEBOUNCE = 500;

export const STARTER_TEMPLATE_NAME = 'Getting-Started';

export const pipelineEditorTrackingOptions = {
  label: 'pipeline_editor',
  actions: {
    browse_templates: 'browse_templates',
  },
};

export const TEMPLATE_REPOSITORY_URL =
  'https://gitlab.com/gitlab-org/gitlab-foss/tree/master/lib/gitlab/ci/templates';

export const COMMIT_SHA_POLL_INTERVAL = 1000;
