import { pickBy } from 'lodash';
import { SUPPORTED_FILTER_PARAMETERS } from './constants';

export const validateParams = params => {
  return pickBy(params, (val, key) => SUPPORTED_FILTER_PARAMETERS.includes(key) && val);
};

export default () => {};
