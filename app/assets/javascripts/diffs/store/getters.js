import { __, n__ } from '~/locale';
import { getParameterValues } from '~/lib/utils/url_utility';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  INLINE_DIFF_LINES_KEY,
} from '../constants';
import { computeSuggestionCommitMessage } from '../utils/suggestions';
import { parallelizeDiffLines } from './utils';

export * from './getters_versions_dropdowns';

export const isParallelView = (state) => state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;

export const isInlineView = (state) => state.diffViewType === INLINE_DIFF_VIEW_TYPE;

export const whichCollapsedTypes = (state) => {
  const automatic = state.diffFiles.some((file) => file.viewer?.automaticallyCollapsed);
  const manual = state.diffFiles.some((file) => file.viewer?.manuallyCollapsed);

  return {
    any: automatic || manual,
    automatic,
    manual,
  };
};

export const commitId = (state) => (state.commit && state.commit.id ? state.commit.id : null);

/**
 * Checks if the diff has all discussions expanded
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllExpandedDiscussions = (state, getters) => (diff) => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions && discussions.length && discussions.every((discussion) => discussion.expanded)) ||
    false
  );
};

/**
 * Checks if the diff has all discussions collapsed
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasAllCollapsedDiscussions = (state, getters) => (diff) => {
  const discussions = getters.getDiffFileDiscussions(diff);

  return (
    (discussions &&
      discussions.length &&
      discussions.every((discussion) => !discussion.expanded)) ||
    false
  );
};

/**
 * Checks if the diff has any open discussions
 * @param {Object} diff
 * @returns {Boolean}
 */
export const diffHasExpandedDiscussions = () => (diff) => {
  const diffLineDiscussionsExpanded = diff[INLINE_DIFF_LINES_KEY].filter(
    (l) => l.discussions.length >= 1,
  ).some((l) => l.discussionsExpanded);
  const diffFileDiscussionsExpanded = diff.discussions?.some((d) => d.expandedOnDiff);

  return diffFileDiscussionsExpanded || diffLineDiscussionsExpanded;
};

/**
 * Checks if every diff has every discussion open
 * @returns {Boolean}
 */
export const allDiffDiscussionsExpanded = (state) => {
  return state.diffFiles.every((diff) => {
    const highlightedLines = diff[INLINE_DIFF_LINES_KEY];
    if (highlightedLines.length) {
      return highlightedLines
        .filter((l) => l.discussions.length >= 1)
        .every((l) => l.discussionsExpanded);
    }
    if (diff.viewer.name === 'image') {
      return diff.discussions.every((discussion) => discussion.expandedOnDiff);
    }
    return true;
  });
};

/**
 * Checks if the diff has any discussion
 * @param {Boolean} diff
 * @returns {Boolean}
 */
export const diffHasDiscussions = () => (diff) => {
  return (
    diff.discussions?.length >= 1 ||
    diff[INLINE_DIFF_LINES_KEY].some((l) => l.discussions.length >= 1)
  );
};

/**
 * Returns an array with the discussions of the given diff
 * @param {Object} diff
 * @returns {Array}
 */
// eslint-disable-next-line max-params
export const getDiffFileDiscussions = (state, getters, rootState, rootGetters) => (diff) =>
  rootGetters.discussions.filter(
    (discussion) => discussion.diff_discussion && discussion.diff_file.file_hash === diff.file_hash,
  ) || [];

export const getDiffFileByHash = (state) => (fileHash) =>
  state.diffFiles.find((file) => file.file_hash === fileHash);

export function isTreePathLoaded(state) {
  return (path) => {
    return Boolean(state.treeEntries[path]?.diffLoaded);
  };
}

export const flatBlobsList = (state) =>
  Object.values(state.treeEntries).filter((f) => f.type === 'blob');

export const allBlobs = (state, getters) =>
  getters.flatBlobsList.reduce((acc, file) => {
    const { parentPath } = file;

    if (parentPath && !acc.some((f) => f.path === parentPath)) {
      acc.push({
        path: parentPath,
        isHeader: true,
        tree: [],
      });
    }

    const id = state.diffFiles.find((diff) => diff.file_hash === file.fileHash)?.id;
    acc.find((f) => f.path === parentPath).tree.push({ ...file, id });

    return acc;
  }, []);

export const getCommentFormForDiffFile = (state) => (fileHash) =>
  state.commentForms.find((form) => form.fileHash === fileHash);

/**
 * Returns the test coverage hits for a specific line of a given file
 * @param {string} file
 * @param {number} line
 * @returns {number}
 */
export const fileLineCoverage = (state) => (file, line) => {
  if (!state.coverageFiles.files) return {};
  const fileCoverage = state.coverageFiles.files[file];
  if (!fileCoverage) return {};
  const lineCoverage = fileCoverage[String(line)];

  if (lineCoverage === 0) {
    return { text: __('No test coverage'), class: 'no-coverage' };
  }
  if (lineCoverage >= 0) {
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
export const currentDiffIndex = (state) =>
  Math.max(
    0,
    flatBlobsList(state).findIndex((diff) => diff.fileHash === state.currentDiffFileId),
  );

export const diffLines = (state) => (file) => {
  return parallelizeDiffLines(
    file.highlighted_diff_lines || [],
    state.diffViewType === INLINE_DIFF_VIEW_TYPE,
  );
};

export function suggestionCommitMessage(state, _, rootState) {
  return (values = {}) =>
    computeSuggestionCommitMessage({
      message: state.defaultSuggestionCommitMessage,
      values: {
        branch_name: rootState.page.mrMetadata.branch_name,
        project_path: rootState.page.mrMetadata.project_path,
        project_name: rootState.page.mrMetadata.project_name,
        username: rootState.page.mrMetadata.username,
        user_full_name: rootState.page.mrMetadata.user_full_name,
        ...values,
      },
    });
}

export const isVirtualScrollingEnabled = (state) => {
  if (state.disableVirtualScroller || getParameterValues('virtual_scrolling')[0] === 'false') {
    return false;
  }

  return !state.viewDiffsFileByFile;
};

export const isBatchLoading = (state) => state.batchLoadingState === 'loading';
export const isBatchLoadingError = (state) => state.batchLoadingState === 'error';

export const diffFiles = (state, getters) => {
  const { linkedFile } = getters;
  if (linkedFile) {
    const diffs = state.diffFiles.slice(0);
    diffs.splice(diffs.indexOf(linkedFile), 1);
    return [linkedFile, ...diffs];
  }
  return state.diffFiles;
};

export const linkedFile = (state) => {
  if (!state.linkedFileHash) return null;
  return state.diffFiles.find((file) => file.file_hash === state.linkedFileHash);
};

export const fileTree = (state) => {
  const diffs = state.diffFiles;
  const mapToId = (item) => {
    const id = diffs.find((diff) => diff.file_hash === item.fileHash)?.id;
    const tree = item.tree.map(mapToId);
    return { ...item, id, tree };
  };
  return state.tree.map(mapToId);
};
