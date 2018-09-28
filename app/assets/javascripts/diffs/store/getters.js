import _ from 'underscore';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';

export const isParallelView = state => state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;

export const isInlineView = state => state.diffViewType === INLINE_DIFF_VIEW_TYPE;

export const areAllFilesCollapsed = state => state.diffFiles.every(file => file.collapsed);

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
 * Checks if the diff has all discussions collpased
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllCollpasedDiscussions = (state, getters) => diff => {
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
    discussion =>
      discussion.diff_discussion && _.isEqual(discussion.diff_file.file_hash, diff.fileHash),
  ) || [];

export const shouldRenderParallelCommentRow = state => line => {
  const hasDiscussion =
    (line.left && line.left.discussions && line.left.discussions.length) ||
    (line.right && line.right.discussions && line.right.discussions.length);

  const hasExpandedDiscussionOnLeft =
    line.left && line.left.discussions && line.left.discussions.length
      ? line.left.discussions.every(discussion => discussion.expanded)
      : false;
  const hasExpandedDiscussionOnRight =
    line.right && line.right.discussions && line.right.discussions.length
      ? line.right.discussions.every(discussion => discussion.expanded)
      : false;

  if (hasDiscussion && (hasExpandedDiscussionOnLeft || hasExpandedDiscussionOnRight)) {
    return true;
  }

  const hasCommentFormOnLeft = line.left && state.diffLineCommentForms[line.left.lineCode];
  const hasCommentFormOnRight = line.right && state.diffLineCommentForms[line.right.lineCode];

  return hasCommentFormOnLeft || hasCommentFormOnRight;
};

export const shouldRenderInlineCommentRow = state => line => {
  if (state.diffLineCommentForms[line.lineCode]) return true;

  if (!line.discussions || line.discussions.length === 0) {
    return false;
  }

  return line.discussions.every(discussion => discussion.expanded);
};

// prevent babel-plugin-rewire from generating an invalid default during karma∂ tests
export const getDiffFileByHash = state => fileHash =>
  state.diffFiles.find(file => file.fileHash === fileHash);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
