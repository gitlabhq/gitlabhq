/**
 * Normalizes a directory path to ensure consistent format.
 * - Ensures path starts with a slash
 * - Removes trailing slash (except for root path)
 *
 * @param {string} dirPath - The path to normalize
 * @returns {string} - The normalized path
 */
export const normalizePath = (dirPath) => {
  let path = dirPath;
  if (!path.startsWith('/')) path = `/${path}`;
  if (path !== '/' && path.endsWith('/')) path = path.slice(0, -1);
  return path;
};

/**
 * Removes duplicates from an array based on flatPath and id.
 *
 * @param {Array} arr - Array to deduplicate
 * @returns {Array} - Deduplicated array
 */
export const dedupeByFlatPathAndId = (arr) => {
  const seen = new Set();
  return arr.filter((item) => {
    const key = `${item.flatPath}:${item.id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

/**
 * Generates a show more item for the file-row component.
 * @param {string} id - Unique id for the entry
 * @param {string} parentPath - The path of the parent directory
 * @param {number} level - Level used for indentation in rendering the tree
 * @returns {Object} Show more item object with id, level, parentPath, and isShowMore properties
 */
export const generateShowMoreItem = (id, parentPath, level) => ({
  id: `${id}-show-more`,
  level,
  parentPath,
  isShowMore: true,
});
