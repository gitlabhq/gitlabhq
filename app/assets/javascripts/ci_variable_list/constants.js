import { __ } from '~/locale';

// eslint-disable import/prefer-default-export
export const ADD_CI_VARIABLE_MODAL_ID = 'add-ci-variable';

export const displayText = {
  variableText: __('Var'),
  fileText: __('File'),
  allEnvironmentsText: __('All'),
};

export const types = {
  variableType: 'env_var',
  fileType: 'file',
  allEnvironmentsType: '*',
};
