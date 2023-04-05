import { __, s__, sprintf } from '~/locale';

export const ADD_CI_VARIABLE_MODAL_ID = 'add-ci-variable';
export const ENVIRONMENT_QUERY_LIMIT = 30;

export const SORT_DIRECTIONS = {
  ASC: 'KEY_ASC',
  DESC: 'KEY_DESC',
};

// This const will be deprecated once we remove VueX from the section
export const displayText = {
  variableText: __('Variable'),
  fileText: __('File'),
  allEnvironmentsText: __('All (default)'),
};

export const variableTypes = {
  envType: 'ENV_VAR',
  fileType: 'FILE',
};

// Once REST is removed, we won't need `types`
export const types = {
  variableType: 'env_var',
  fileType: 'file',
};

export const allEnvironments = {
  type: '*',
  text: __('All (default)'),
};

// Once REST is removed, we won't need `types` key
export const variableText = {
  [types.variableType]: __('Variable'),
  [types.fileType]: __('File'),
  [variableTypes.envType]: __('Variable'),
  [variableTypes.fileType]: __('File'),
};

export const variableOptions = [
  { value: variableTypes.envType, text: variableText[variableTypes.envType] },
  { value: variableTypes.fileType, text: variableText[variableTypes.fileType] },
];

export const defaultVariableState = {
  environmentScope: allEnvironments.type,
  key: '',
  masked: false,
  protected: false,
  raw: false,
  value: '',
  variableType: variableTypes.envType,
};

// eslint-disable-next-line @gitlab/require-i18n-strings
export const groupString = 'Group';
// eslint-disable-next-line @gitlab/require-i18n-strings
export const instanceString = 'Instance';
// eslint-disable-next-line @gitlab/require-i18n-strings
export const projectString = 'Project';

export const AWS_TIP_DISMISSED_COOKIE_NAME = 'ci_variable_list_constants_aws_tip_dismissed';
export const AWS_TIP_MESSAGE = __(
  '%{deployLinkStart}Use a template to deploy to ECS%{deployLinkEnd}, or use a docker image to %{commandsLinkStart}run AWS commands in GitLab CI/CD%{commandsLinkEnd}.',
);

export const EVENT_LABEL = 'ci_variable_modal';
export const EVENT_ACTION = 'validation_error';

// AWS TOKEN CONSTANTS
export const AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID';
export const AWS_DEFAULT_REGION = 'AWS_DEFAULT_REGION';
export const AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY';
export const AWS_TOKEN_CONSTANTS = [AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY];

export const CONTAINS_VARIABLE_REFERENCE_MESSAGE = __(
  'Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
);
export const DEFAULT_EXCEEDS_VARIABLE_LIMIT_TEXT = s__(
  'CiVariables|You have reached the maximum number of variables available. To add new variables, you must reduce the number of defined variables.',
);
export const ENVIRONMENT_SCOPE_LINK_TITLE = __('Learn more');
export const EXCEEDS_VARIABLE_LIMIT_TEXT = s__(
  'CiVariables|This %{entity} has %{currentVariableCount} defined CI/CD variables. The maximum number of variables per %{entity} is %{maxVariableLimit}. To add new variables, you must reduce the number of defined variables.',
);
export const FLAG_LINK_TITLE = s__('CiVariable|Define a CI/CD variable in the UI');
export const MAXIMUM_VARIABLE_LIMIT_REACHED = s__(
  'CiVariables|Maximum number of variables reached.',
);

export const ADD_VARIABLE_ACTION = 'ADD_VARIABLE';
export const EDIT_VARIABLE_ACTION = 'EDIT_VARIABLE';
export const VARIABLE_ACTIONS = [ADD_VARIABLE_ACTION, EDIT_VARIABLE_ACTION];

export const ADD_MUTATION_ACTION = 'add';
export const UPDATE_MUTATION_ACTION = 'update';
export const DELETE_MUTATION_ACTION = 'delete';

export const ADD_VARIABLE_TOAST = (key) =>
  sprintf(s__('CiVariable|Variable %{key} has been successfully added.'), { key });
export const UPDATE_VARIABLE_TOAST = (key) =>
  sprintf(s__('CiVariable|Variable %{key} has been updated.'), { key });
export const DELETE_VARIABLE_TOAST = (key) =>
  sprintf(s__('CiVariable|Variable %{key} has been deleted.'), { key });

export const mapMutationActionToToast = {
  [ADD_MUTATION_ACTION]: ADD_VARIABLE_TOAST,
  [UPDATE_MUTATION_ACTION]: UPDATE_VARIABLE_TOAST,
  [DELETE_MUTATION_ACTION]: DELETE_VARIABLE_TOAST,
};

export const EXPANDED_VARIABLES_NOTE = __(
  '%{codeStart}$%{codeEnd} will be treated as the start of a reference to another variable.',
);

export const environmentFetchErrorText = __(
  'There was an error fetching the environments information.',
);
export const genericMutationErrorText = __('Something went wrong on our end. Please try again.');
export const variableFetchErrorText = __('There was an error fetching the variables.');
