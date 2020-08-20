import { has, mapKeys, pick } from 'lodash';

/**
 * This method is used to type-safely set values on the given object
 *
 * @template T
 * @returns {T} A shallow copy of `obj`, with the values from `values`
 * @throws {Error} If `values` contains a key that isn't already on `obj`
 * @param {T} source
 * @param {Object} values
 */
export const withValues = (source, values) =>
  Object.entries(values).reduce(
    (acc, [key, value]) => {
      if (!has(acc, key)) {
        throw new Error(
          `[mock_server] Cannot write property that does not exist on object '${key}'`,
        );
      }

      return {
        ...acc,
        [key]: value,
      };
    },
    { ...source },
  );

/**
 * This method returns a subset of the given object and maps the key names based on the
 * given `keys`.
 *
 * @param {Object} obj The source object.
 * @param {Object} map The object which contains the keys to use and mapped key names.
 */
export const withKeys = (obj, map) => mapKeys(pick(obj, Object.keys(map)), (val, key) => map[key]);
