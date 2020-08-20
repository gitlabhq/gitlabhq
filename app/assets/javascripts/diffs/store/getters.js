import { __, n__ } from '~/locale';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';

export * from './getters_versions_dropdowns';

export const isParallelView = state => state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;

export const isInlineView = state => state.diffViewType === INLINE_DIFF_VIEW_TYPE;

export const hasCollapsedFile = state =>
  state.diffFiles.some(file => file.viewer && file.viewer.collapsed);

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

export const getDiffFileByHash = state => fileHash =>
  state.diffFiles.find(file => file.file_hash === fileHash);

export const flatBlobsList = state =>
  Object.values(state.treeEntries).filter(f => f.type === 'blob');

export const allBlobs = (state, getters) =>
  getters.flatBlobsList.reduce((acc, file) => {
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

export const getCommentFormForDiffFile = state => fileHash =>
  state.commentForms.find(form => form.fileHash === fileHash);

/**
 * Returns the test coverage hits for a specific line of a given file
 * @param {string} file
 * @param {number} line
 * @returns {number}
 */
export const fileLineCoverage = state => (file, line) => {
  if (!state.coverageFiles.files) return {};
  const fileCoverage = state.coverageFiles.files[file];
  if (!fileCoverage) return {};
  const lineCoverage = fileCoverage[String(line)];

  if (lineCoverage === 0) {
    return { text: __('No test coverage'), class: 'no-coverage' };
  } else if (lineCoverage >= 0) {
    return {
      text: n__('Test coverage: %d hit', 'Test coverage: %d hits', lineCoverage),
      class: 'coverage',
    };
  }
  return {};
};

/**
 * Returns index of a currently selected diff in diffFiles
 * @returns {number}
 */
export const currentDiffIndex = state =>
  Math.max(0, state.diffFiles.findIndex(diff => diff.file_hash === state.currentDiffFileId));
