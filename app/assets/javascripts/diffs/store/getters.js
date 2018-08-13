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

  return (discussions.length && discussions.every(discussion => discussion.expanded)) || false;
};

/**
 * Checks if the diff has all discussions collpased
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllCollpasedDiscussions = (state, getters) => diff => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (discussions.length && discussions.every(discussion => !discussion.expanded)) || false;
};

/**
 * Checks if the diff has any open discussions
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasExpandedDiscussions = (state, getters) => diff => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions.length && discussions.find(discussion => discussion.expanded) !== undefined) ||
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

export const singleDiscussionByLineCodeOld = (
  state,
  getters,
  rootState,
  rootGetters,
) => lineCode => {
  if (!lineCode || lineCode === undefined) return [];
  const discussions = rootGetters.discussionsByLineCode;
  return discussions[lineCode] || [];
};

/**
 * Returns an Object with discussions by their diff line code
 * To avoid rendering outdated discussions on the Changes tab we should do a bunch of SHA
 * comparisions. `note.position.formatter` have the current version diff refs but
 * `note.original_position.formatter` will have the first version's diff refs.
 * If line diff refs matches with one of them, we should render it as a discussion on Changes tab.
 *
 * @param {Object} diff
 * @returns {Array}
 */
export const discussionsByLineCode = (state, getters, rootState, rootGetters) => {
  const diffRefsByLineCode = getDiffRefsByLineCode(state.diffFiles);

  return rootGetters.discussions.reduce((acc, note) => {
    const isDiffDiscussion = note.diff_discussion;
    const hasLineCode = note.line_code;
    const isResolvable = note.resolvable;
    const diffRefs = diffRefsByLineCode[note.line_code];

    if (isDiffDiscussion && hasLineCode && isResolvable && diffRefs) {
      const refs = convertObjectPropsToCamelCase(note.position.formatter);
      const originalRefs = convertObjectPropsToCamelCase(note.original_position.formatter);

      if (_.isEqual(refs, diffRefs) || _.isEqual(originalRefs, diffRefs)) {
        const lineCode = note.line_code;

        if (acc[lineCode]) {
          acc[lineCode].push(note);
        } else {
          acc[lineCode] = [note];
        }
      }
    }

    return acc;
  }, {});
};

export const shouldRenderParallelCommentRow = (state, getters) => line => {
  const hasDiscussion =
    (line.left && line.left.discussions.length) || (line.right && line.right.discussions.length);

  const hasExpandedDiscussionOnLeft =
    line.left && line.left.discussions.length
      ? line.left.discussions.every(discussion => discussion.expanded)
      : false;
  const hasExpandedDiscussionOnRight =
    line.right && line.right.discussions.length
      ? line.right.discussions.every(discussion => discussion.expanded)
      : false;

  if (hasDiscussion && (hasExpandedDiscussionOnLeft || hasExpandedDiscussionOnRight)) {
    return true;
  }

  const hasCommentFormOnLeft = line.left && state.diffLineCommentForms[line.left.lineCode];
  const hasCommentFormOnRight = line.right && state.diffLineCommentForms[line.right.lineCode];

  return hasCommentFormOnLeft || hasCommentFormOnRight;
};

export const shouldRenderInlineCommentRow = (state, getters) => line => {
  if (state.diffLineCommentForms[line.lineCode]) return true;

  const lineDiscussions = getters.singleDiscussionByLineCode(line.lineCode);
  if (lineDiscussions.length === 0) {
    return false;
  }

  return lineDiscussions.every(discussion => discussion.expanded);
};

// prevent babel-plugin-rewire from generating an invalid default during karma∂ tests
export const getDiffFileByHash = state => fileHash =>
  state.diffFiles.find(file => file.fileHash === fileHash);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
