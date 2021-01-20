import { __ } from '~/locale';

/**
 * Return a empty string when passed a value of 'Any'
 *
 * @param {String} value
 * @returns {String}
 */
export const isAny = (value) => {
  return value === __('Any') ? '' : value;
};
