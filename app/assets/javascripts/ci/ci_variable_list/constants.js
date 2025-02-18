import { __, s__, sprintf } from '~/locale';

export const MASKED_VALUE_MIN_LENGTH = 8;

export const WHITESPACE_REG_EX = /\s/;

export const SORT_DIRECTIONS = {
  ASC: 'KEY_ASC',
  DESC: 'KEY_DESC',
};
export const variableTypes = {
  envType: 'ENV_VAR',
  fileType: 'FILE',
};

export const variableOptions = [
  { value: variableTypes.envType, text: __('Variable (default)') },
  { value: variableTypes.fileType, text: __('File') },
];

export const VISIBILITY_HIDDEN = 'MASKED_AND_HIDDEN';
export const VISIBILITY_MASKED = 'MASKED';
export const VISIBILITY_VISIBLE = 'VISIBLE';

export const visibilityToAttributesMap = {
  [VISIBILITY_HIDDEN]: { masked: true, hidden: true },
  [VISIBILITY_MASKED]: { masked: true, hidden: false },
  [VISIBILITY_VISIBLE]: { masked: false, hidden: false },
};

export const defaultVariableState = {
  description: null,
  environmentScope: '*',
  key: '',
  masked: false,
  hidden: false,
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
export const AWS_TIP_TITLE = s__('CiVariable|Use OIDC to securely connect to cloud services');
export const AWS_TIP_MESSAGE = s__(
  'CiVariable|GitLab CI/CD supports OpenID Connect (OIDC) to give your build and deployment jobs access to cloud credentials and services. %{linkStart}How do I configure OIDC for my cloud provider?%{linkEnd}',
);

export const DRAWER_EVENT_LABEL = 'ci_variable_drawer';
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
export const EXCEEDS_VARIABLE_LIMIT_TEXT = s__(
  'CiVariables|This %{entity} has %{currentVariableCount} defined CI/CD variables. The maximum number of variables per %{entity} is %{maxVariableLimit}. To add new variables, you must reduce the number of defined variables.',
);
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

export const genericMutationErrorText = __('Something went wrong on our end. Please try again.');
export const variableFetchErrorText = __('There was an error fetching the variables.');
