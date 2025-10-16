import { FTB_MAX_DEPTH, FTB_MAX_PAGES } from '~/repository/constants';

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
  if (!path?.startsWith('/')) path = `/${path}`;
  if (path !== '/' && path?.endsWith('/')) path = path?.slice(0, -1);
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

/**
 * Checks if a directory contains a specific child by name
 * @param {Object} directoryContents - Directory contents object
 * @param {Array} directoryContents.trees - Array of tree objects in the directory
 * @param {string} childName - Name of the child to search for
 * @returns {boolean} True if the child exists in the directory
 */
export const directoryContainsChild = (directoryContents, childName) =>
  directoryContents.trees.some((tree) => tree.name === childName);

/**
 * Checks if we've reached pagination limits or if the path is currently loading
 * @param {number} currentPage - Current page number
 * @param {boolean} isPathLoading - Whether the path is currently being loaded
 * @returns {boolean} True if pagination should stop
 */
export const shouldStopPagination = (currentPage, isPathLoading) =>
  currentPage >= FTB_MAX_PAGES || isPathLoading;

/**
 * Checks if there are more pages available to fetch
 * @param {Object} directoryContents - Directory contents object
 * @param {Object} [directoryContents.pageInfo] - Pagination information
 * @param {boolean} [directoryContents.pageInfo.hasNextPage] - Whether there are more pages
 * @returns {boolean} True if more pages are available
 */
export const hasMorePages = (directoryContents) => Boolean(directoryContents.pageInfo?.hasNextPage);

/**
 * Checks if a path is valid for expansion based on depth constraints
 * @param {string[]} segments - Array of path segments
 * @returns {boolean} True if the path can be expanded
 */
export const isExpandable = (segments) => segments.length > 0 && segments.length <= FTB_MAX_DEPTH;

/**
 * Handles keyboard navigation for ARIA tree view pattern
 * @param {KeyboardEvent} event - The keyboard event
 */
export const handleTreeKeydown = (event) => {
  const items = Array.from(event.currentTarget.querySelectorAll('[role="treeitem"]'));
  const target = event.target.closest('[role="treeitem"]');
  const currentIndex = target ? items.indexOf(target) : -1;

  if (currentIndex === -1) return;

  let nextIndex;
  switch (event.key) {
    case 'ArrowDown':
      nextIndex = Math.min(currentIndex + 1, items.length - 1);
      break;
    case 'ArrowUp':
      nextIndex = Math.max(currentIndex - 1, 0);
      break;
    default:
      return;
  }

  event.preventDefault();
  items[nextIndex]?.focus();
};
