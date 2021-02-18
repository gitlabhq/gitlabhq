import { isString } from 'lodash';
import { __ } from '~/locale';

export const UNEXPECTED_ERROR = __('Unexpected error');

export const getErrorMessage = (e) => {
  if (!e) {
    return UNEXPECTED_ERROR;
  }
  if (isString(e)) {
    return e;
  }

  return e.message || e.networkError || UNEXPECTED_ERROR;
};
