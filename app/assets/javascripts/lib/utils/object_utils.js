import { camelCase } from 'lodash';

/**
 * Transforms object keys
 *
 * @param  {Object} object
 * @param  {Function} transformer
 * @return {Object}
 */
export function transformKeys(object, transformer) {
  return Object.fromEntries(
    Object.entries(object).map(([key, value]) => [transformer(key), value]),
  );
}

/**
 * Transform object keys to camelCase
 *
 * @param  {Object} object
 * @return {Object}
 */
export function camelizeKeys(object) {
  return transformKeys(object, camelCase);
}
