import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';

export const isParallelView = state => state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;

export const isInlineView = state => state.diffViewType === INLINE_DIFF_VIEW_TYPE;

export const hasCollapsedFile = state => state.diffFiles.some(file => file.collapsed);

export const commitId = state => (state.commit && state.commit.id ? state.commit.id : null);

/**
 * Checks if the diff has all discussions expanded
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllExpandedDiscussions = (state, getters) => diff => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions && discussions.length && discussions.every(discussion => discussion.expanded)) ||
    false
  );
};

/**
 * Checks if the diff has all discussions collapsed
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllCollapsedDiscussions = (state, getters) => diff => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions && discussions.length && discussions.every(discussion => !discussion.expanded)) ||
    false
  );
};

/**
 * Checks if the diff has any open discussions
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasExpandedDiscussions = (state, getters) => diff => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions &&
      discussions.length &&
      discussions.find(discussion => discussion.expanded) !== undefined) ||
    false
  );
};

/**
 * Checks if the diff has any discussion
 * @param {Boolean} diff
 * @returns {Boolean}
 */
export const diffHasDiscussions = (state, getters) => diff =>
  getters.getDiffFileDiscussions(diff).length > 0;

/**
 * Returns an array with the discussions of the given diff
 * @param {Object} diff
 * @returns {Array}
 */
export const getDiffFileDiscussions = (state, getters, rootState, rootGetters) => diff =>
  rootGetters.discussions.filter(
    discussion => discussion.diff_discussion && discussion.diff_file.file_hash === diff.file_hash,
  ) || [];

// prevent babel-plugin-rewire from generating an invalid default during karma∂ tests
export const getDiffFileByHash = state => fileHash =>
  state.diffFiles.find(file => file.file_hash === fileHash);

export const allBlobs = state =>
  Object.values(state.treeEntries)
    .filter(f => f.type === 'blob')
    .reduce((acc, file) => {
      const { parentPath } = file;

      if (parentPath && !acc.some(f => f.path === parentPath)) {
        acc.push({
          path: parentPath,
          isHeader: true,
          tree: [],
        });
      }

      acc.find(f => f.path === parentPath).tree.push(file);

      return acc;
    }, []);

export const diffFilesLength = state => state.diffFiles.length;

export const getCommentFormForDiffFile = state => fileHash =>
  state.commentForms.find(form => form.fileHash === fileHash);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
