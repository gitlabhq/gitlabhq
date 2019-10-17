/**
 * Checks if the first argument is a subset of the second argument.
 * @param {Set} subset The set to be considered as the subset.
 * @param {Set} superset The set to be considered as the superset.
 * @returns {boolean}
 */
// eslint-disable-next-line import/prefer-default-export
export const isSubset = (subset, superset) =>
  Array.from(subset).every(value => superset.has(value));
