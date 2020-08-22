import { __ } from '~/locale';

export const ADD_CI_VARIABLE_MODAL_ID = 'add-ci-variable';

export const displayText = {
  variableText: __('Variable'),
  fileText: __('File'),
  allEnvironmentsText: __('All (default)'),
};

export const types = {
  variableType: 'env_var',
  fileType: 'file',
  allEnvironmentsType: '*',
};

export const AWS_TIP_DISMISSED_COOKIE_NAME = 'ci_variable_list_constants_aws_tip_dismissed';
export const AWS_TIP_MESSAGE = __(
  '%{deployLinkStart}Use a template to deploy to ECS%{deployLinkEnd}, or use a docker image to %{commandsLinkStart}run AWS commands in GitLab CI/CD%{commandsLinkEnd}.',
);

// AWS TOKEN CONSTANTS
export const AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID';
export const AWS_DEFAULT_REGION = 'AWS_DEFAULT_REGION';
export const AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY';
export const AWS_TOKEN_CONSTANTS = [AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY];
