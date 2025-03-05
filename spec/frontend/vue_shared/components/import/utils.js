/**
 * Convenience function for searching for matches in top-level items and nested items in the Items data for import tables
 * @param {Array} items Items to count
 * @param {Function} filter Filter function to return matches
 * @returns number
 */
export const countItemsAndNested = (items, filter) => {
  const topLevelMatches = items.filter(filter);
  const nestedMatches = items
    .filter((i) => i.nestedRow)
    .map((i) => i.nestedRow)
    .filter(filter);
  return topLevelMatches.length + nestedMatches.length;
};
