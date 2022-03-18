import { s__ } from '~/locale';

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

export const RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME = 'runners_availability_section';
export const RUNNERS_SETTINGS_LINK_CLICKED_EVENT = 'runners_settings_link_clicked';
export const RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT = 'runners_documentation_link_clicked';
export const RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT = 'runners_settings_button_clicked';
export const I18N = {
  title: s__('Pipelines|Get started with GitLab CI/CD'),
  runners: {
    title: s__('Pipelines|Runners are available to run your jobs now'),
    subtitle: s__(
      'Pipelines|GitLab Runner is an application that works with GitLab CI/CD to run jobs in a pipeline. There are active runners available to run your jobs right now. If you prefer, you can %{settingsLinkStart}configure your runners%{settingsLinkEnd} or %{docsLinkStart}learn more%{docsLinkEnd} about runners.',
    ),
  },
  noRunners: {
    title: s__('Pipelines|No runners detected'),
    subtitle: s__(
      'Pipelines|A GitLab Runner is an application that works with GitLab CI/CD to run jobs in a pipeline. Install GitLab Runner and register your own runners to get started with CI/CD.',
    ),
    cta: s__('Pipelines|Install GitLab Runner'),
  },
  learnBasics: {
    title: s__('Pipelines|Learn the basics of pipelines and .yml files'),
    subtitle: s__(
      'Pipelines|Use a sample %{codeStart}.gitlab-ci.yml%{codeEnd} template file to explore how CI/CD works.',
    ),
    gettingStarted: {
      title: s__('Pipelines|"Hello world" with GitLab CI'),
      description: s__(
        'Pipelines|Get familiar with GitLab CI syntax by  setting up a simple pipeline running a  "Hello world" script to see how it runs, explore how CI/CD works.',
      ),
      cta: s__('Pipelines|Try test template'),
    },
  },
  templates: {
    title: s__('Pipelines|Ready to set up CI/CD for your project?'),
    subtitle: s__(
      "Pipelines|Use a template based on your project's language or framework to get started with GitLab CI/CD.",
    ),
    description: s__('Pipelines|CI/CD template to test and deploy your %{name} project.'),
    cta: s__('Pipelines|Use template'),
  },
};
