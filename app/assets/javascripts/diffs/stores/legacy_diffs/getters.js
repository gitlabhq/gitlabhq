import { __, n__, sprintf } from '~/locale';
import { getParameterValues, getParameterByName } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  INLINE_DIFF_LINES_KEY,
  DIFF_COMPARE_BASE_VERSION_INDEX,
  DIFF_COMPARE_HEAD_VERSION_INDEX,
} from '~/diffs/constants';
import { useNotes } from '~/notes/store/legacy_notes';
import { computeSuggestionCommitMessage } from '../../utils/suggestions';
import { parallelizeDiffLines } from '../../store/utils';

export function isParallelView() {
  return this.diffViewType === PARALLEL_DIFF_VIEW_TYPE;
}

export function isInlineView() {
  return this.diffViewType === INLINE_DIFF_VIEW_TYPE;
}

export function whichCollapsedTypes() {
  const automatic = this.diffFiles.some((file) => file.viewer?.automaticallyCollapsed);
  const manual = this.diffFiles.some((file) => file.viewer?.manuallyCollapsed);

  return {
    any: automatic || manual,
    automatic,
    manual,
  };
}

export function commitId() {
  return this.commit && this.commit.id ? this.commit.id : null;
}

/**
 * Checks if the diff has all discussions expanded
 * @param {Object} diff
 * @returns {Boolean}
 */
export function diffHasAllExpandedDiscussions() {
  return (diff) => {
    const discussions = this.getDiffFileDiscussions(diff);

    return (
      (discussions &&
        discussions.length &&
        discussions.every((discussion) => discussion.expanded)) ||
      false
    );
  };
}

/**
 * Checks if the diff has all discussions collapsed
 * @param {Object} diff
 * @returns {Boolean}
 */
export function diffHasAllCollapsedDiscussions() {
  return (diff) => {
    const discussions = this.getDiffFileDiscussions(diff);

    return (
      (discussions &&
        discussions.length &&
        discussions.every((discussion) => !discussion.expanded)) ||
      false
    );
  };
}

/**
 * Checks if the diff has any open discussions
 * @param {Object} diff
 * @returns {Boolean}
 */
export function diffHasExpandedDiscussions() {
  return (diff) => {
    const diffLineDiscussionsExpanded = diff[INLINE_DIFF_LINES_KEY].filter(
      (l) => l.discussions.length >= 1,
    ).some((l) => l.discussionsExpanded);
    const diffFileDiscussionsExpanded = diff.discussions?.some((d) => d.expandedOnDiff);

    return diffFileDiscussionsExpanded || diffLineDiscussionsExpanded;
  };
}

/**
 * Checks if every diff has every discussion open
 * @returns {Boolean}
 */
export function allDiffDiscussionsExpanded() {
  return this.diffFiles.every((diff) => {
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
}

/**
 * Checks if the diff has any discussion
 * @param {Boolean} diff
 * @returns {Boolean}
 */
export function diffHasDiscussions() {
  return (diff) => {
    return (
      diff.discussions?.length >= 1 ||
      diff[INLINE_DIFF_LINES_KEY].some((l) => l.discussions.length >= 1)
    );
  };
}

/**
 * Returns an array with the discussions of the given diff
 * @param {Object} diff
 * @returns {Array}
 */
export function getDiffFileDiscussions() {
  return (diff) =>
    useNotes().discussions.filter(
      (discussion) =>
        discussion.diff_discussion && discussion.diff_file.file_hash === diff.file_hash,
    ) || [];
}

export function getDiffFileByHash() {
  return (fileHash) => this.diffFiles.find((file) => file.file_hash === fileHash);
}

export function isTreePathLoaded() {
  return (path) => {
    return Boolean(this.treeEntries[path]?.diffLoaded);
  };
}

export function flatBlobsList() {
  return Object.values(this.treeEntries).filter((f) => f.type === 'blob');
}

export function allBlobs() {
  return this.flatBlobsList.reduce((acc, file) => {
    const { parentPath } = file;

    if (parentPath && !acc.some((f) => f.path === parentPath)) {
      acc.push({
        path: parentPath,
        isHeader: true,
        tree: [],
      });
    }

    const id = this.diffFiles.find((diff) => diff.file_hash === file.fileHash)?.id;
    acc.find((f) => f.path === parentPath).tree.push({ ...file, id });

    return acc;
  }, []);
}

export function getCommentFormForDiffFile() {
  return (fileHash) => this.commentForms.find((form) => form.fileHash === fileHash);
}

/**
 * Returns the test coverage hits for a specific line of a given file
 * @param {string} file
 * @param {number} line
 * @returns {number}
 */
export function fileLineCoverage() {
  return (file, line) => {
    if (!this.coverageFiles.files) return {};
    const fileCoverage = this.coverageFiles.files[file];
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
}

/**
 * Returns index of a currently selected diff in diffFiles
 * @returns {number}
 */
export function currentDiffIndex() {
  return Math.max(
    0,
    this.flatBlobsList.findIndex((diff) => diff.fileHash === this.currentDiffFileId),
  );
}

export function diffLines() {
  return (file) => {
    return parallelizeDiffLines(
      file.highlighted_diff_lines || [],
      this.diffViewType === INLINE_DIFF_VIEW_TYPE,
    );
  };
}

export function suggestionCommitMessage() {
  return (values = {}) => {
    const { mrMetadata } = this.tryStore('legacyMrNotes');
    return computeSuggestionCommitMessage({
      message: this.defaultSuggestionCommitMessage,
      values: {
        branch_name: mrMetadata.branch_name,
        project_path: mrMetadata.project_path,
        project_name: mrMetadata.project_name,
        username: mrMetadata.username,
        user_full_name: mrMetadata.user_full_name,
        ...values,
      },
    });
  };
}

export function isVirtualScrollingEnabled() {
  if (this.disableVirtualScroller || getParameterValues('virtual_scrolling')[0] === 'false') {
    return false;
  }

  return !this.viewDiffsFileByFile;
}

export function isBatchLoading() {
  return this.batchLoadingState === 'loading';
}
export function isBatchLoadingError() {
  return this.batchLoadingState === 'error';
}

export function diffFilesFiltered() {
  const { linkedFile: file } = this;
  if (file) {
    const diffs = this.diffFiles.slice(0);
    diffs.splice(diffs.indexOf(file), 1);
    return [file, ...diffs];
  }
  return this.diffFiles;
}

export function linkedFile() {
  if (!this.linkedFileHash) return null;
  return this.diffFiles.find((file) => file.file_hash === this.linkedFileHash);
}

export function selectedTargetIndex() {
  return this.startVersion?.version_index || DIFF_COMPARE_BASE_VERSION_INDEX;
}

export function selectedSourceIndex() {
  if (!this.mergeRequestDiff) return undefined;
  return this.mergeRequestDiff.version_index;
}

export function selectedContextCommitsDiff() {
  return this.contextCommitsDiff && this.contextCommitsDiff.showing_context_commits_diff;
}

export function diffCompareDropdownTargetVersions() {
  if (!this.mergeRequestDiff) return [];
  // startVersion only exists if the user has selected a version other
  // than "base" so if startVersion is null then base must be selected

  const diffHeadParam = getParameterByName('diff_head');
  const diffHead = parseBoolean(diffHeadParam) || !diffHeadParam;
  const isBaseSelected = !this.startVersion;
  const isHeadSelected = !this.startVersion && diffHead;
  let baseVersion = null;

  if (!this.mergeRequestDiff.head_version_path) {
    baseVersion = {
      versionName: this.targetBranchName,
      version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
      href: this.mergeRequestDiff.base_version_path,
      isBase: true,
      selected: isBaseSelected,
    };
  }

  const headVersion = {
    versionName: this.targetBranchName,
    version_index: DIFF_COMPARE_HEAD_VERSION_INDEX,
    href: this.mergeRequestDiff.head_version_path,
    isHead: true,
    selected: isHeadSelected,
  };
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  const formatVersion = (v) => {
    return {
      href: v.compare_path,
      versionName: sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
      selected: v.version_index === this.selectedTargetIndex,
      ...v,
    };
  };

  return [
    ...this.mergeRequestDiffs.slice(1).map(formatVersion),
    baseVersion,
    this.mergeRequestDiff.head_version_path && headVersion,
  ].filter((a) => a);
}

export function diffCompareDropdownSourceVersions() {
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  const versions = this.mergeRequestDiffs.map((v, i) => {
    const isLatestVersion = i === 0;

    return {
      ...v,
      href: v.version_path,
      commitsText: n__(`%d commit,`, `%d commits,`, v.commits_count),
      isLatestVersion,
      versionName: isLatestVersion
        ? __('latest version')
        : sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
      selected: v.version_index === this.selectedSourceIndex && !this.selectedContextCommitsDiffs,
    };
  });

  const { contextCommitsDiff } = this;
  if (contextCommitsDiff) {
    versions.push({
      href: contextCommitsDiff.diffs_path,
      commitsText: n__(`%d commit`, `%d commits`, contextCommitsDiff.commits_count),
      versionName: __('previously merged commits'),
      selected: this.selectedContextCommitsDiffs,
      addDivider: this.mergeRequestDiffs.length > 0,
    });
  }
  return versions;
}

export function fileTree() {
  const diffs = this.diffFiles;
  const mapToId = (item) => {
    const id = diffs.find((diff) => diff.file_hash === item.fileHash)?.id;
    const tree = item.tree.map(mapToId);
    return { ...item, id, tree };
  };
  return this.tree.map(mapToId);
}
