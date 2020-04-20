import { __ } from '~/locale';

// eslint-disable import/prefer-default-export
export const ADD_CI_VARIABLE_MODAL_ID = 'add-ci-variable';

export const displayText = {
  variableText: __('Var'),
  fileText: __('File'),
  allEnvironmentsText: __('All (default)'),
};

export const types = {
  variableType: 'env_var',
  fileType: 'file',
  allEnvironmentsType: '*',
};

// AWS TOKEN CONSTANTS
export const AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID';
export const AWS_DEFAULT_REGION = 'AWS_DEFAULT_REGION';
export const AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY';
