/**
 * Returns a clone of the given object with all __typename keys omitted,
 * including deeply nested ones.
 *
 * Only works with JSON-serializable objects.
 *
 * @param {object} An object with __typename keys (e.g., a GraphQL response)
 * @returns {object} A new object with no __typename keys
 */
export const stripTypenames = (object) => {
  return JSON.parse(
    JSON.stringify(object, (key, value) => (key === '__typename' ? undefined : value)),
  );
};
