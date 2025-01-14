import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  INLINE_DIFF_LINES_KEY,
  EXPANDED_LINE_TYPE,
  FILE_DIFF_POSITION_TYPE,
} from '../../constants';
import * as types from '../../store/mutation_types';
import {
  findDiffFile,
  addLineReferences,
  removeMatchLine,
  addContextLines,
  prepareDiffData,
  isDiscussionApplicableToLine,
  updateLineInFile,
  markTreeEntriesLoaded,
} from '../../store/utils';

export default {
  [types.SET_BASE_CONFIG](options) {
    const {
      endpoint,
      endpointMetadata,
      endpointBatch,
      endpointDiffForPath,
      endpointCoverage,
      endpointUpdateUser,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
      defaultSuggestionCommitMessage,
      viewDiffsFileByFile,
      mrReviews,
      diffViewType,
      perPage,
    } = options;
    Object.assign(this, {
      endpoint,
      endpointMetadata,
      endpointBatch,
      endpointDiffForPath,
      endpointCoverage,
      endpointUpdateUser,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
      defaultSuggestionCommitMessage,
      viewDiffsFileByFile,
      mrReviews,
      diffViewType,
      perPage,
    });
  },

  [types.SET_LOADING](isLoading) {
    Object.assign(this, { isLoading });
  },

  [types.SET_BATCH_LOADING_STATE](batchLoadingState) {
    Object.assign(this, { batchLoadingState });
  },

  [types.SET_RETRIEVING_BATCHES](retrievingBatches) {
    Object.assign(this, { retrievingBatches });
  },

  [types.SET_DIFF_FILES](files) {
    return Object.assign(this, { diffFiles: files });
  },

  [types.SET_DIFF_METADATA](data) {
    Object.assign(this, {
      ...convertObjectPropsToCamelCase(data),
    });
  },

  [types.SET_DIFF_DATA_BATCH]({ diff_files: diffFiles, updatePosition = true }) {
    Object.assign(this, {
      diffFiles: prepareDiffData({
        diff: { diff_files: diffFiles },
        priorFiles: this.diffFiles,
        // when a linked file is added to diffs its position may be incorrect since it's loaded out of order
        // we need to ensure when we load it in batched request it updates it position
        updatePosition,
      }),
      treeEntries: markTreeEntriesLoaded({
        priorEntries: this.treeEntries,
        loadedFiles: diffFiles,
      }),
    });
  },

  [types.SET_DIFF_TREE_ENTRY](diffFile) {
    Object.assign(this, {
      treeEntries: markTreeEntriesLoaded({
        priorEntries: this.treeEntries,
        loadedFiles: [diffFile],
      }),
    });
  },

  [types.SET_COVERAGE_DATA](coverageFiles) {
    Object.assign(this, { coverageFiles, coverageLoaded: true });
  },

  [types.SET_MERGE_REQUEST_DIFFS](mergeRequestDiffs) {
    Object.assign(this, {
      mergeRequestDiffs,
    });
  },

  [types.SET_DIFF_VIEW_TYPE](diffViewType) {
    Object.assign(this, { diffViewType });
  },

  [types.TOGGLE_LINE_HAS_FORM]({ lineCode, fileHash, hasForm }) {
    const diffFile = this.diffFiles.find((f) => f.file_hash === fileHash);

    if (!diffFile) return;

    diffFile[INLINE_DIFF_LINES_KEY].find((l) => l.line_code === lineCode).hasForm = hasForm;
  },

  [types.ADD_CONTEXT_LINES](options) {
    const { lineNumbers, contextLines, fileHash, isExpandDown, nextLineNumbers } = options;
    const { bottom } = options.params;
    const diffFile = findDiffFile(this.diffFiles, fileHash);

    removeMatchLine(diffFile, lineNumbers, bottom);

    const lines = addLineReferences(
      contextLines,
      lineNumbers,
      bottom,
      isExpandDown,
      nextLineNumbers,
    ).map((line) => {
      const lineCode =
        line.type === 'match'
          ? `${fileHash}_${line.meta_data.old_pos}_${line.meta_data.new_pos}_match`
          : line.line_code || `${fileHash}_${line.old_line}_${line.new_line}`;
      return {
        ...line,
        type: line.type || EXPANDED_LINE_TYPE,
        line_code: lineCode,
        discussions: line.discussions || [],
        hasForm: false,
      };
    });

    addContextLines({
      inlineLines: diffFile[INLINE_DIFF_LINES_KEY],
      contextLines: lines,
      bottom,
      lineNumbers,
      isExpandDown,
    });
  },

  [types.ADD_COLLAPSED_DIFFS]({ file, data }) {
    const files = prepareDiffData({ diff: data });
    const [newFileData] = files.filter((f) => f.file_hash === file.file_hash);
    const selectedFile = this.diffFiles.find((f) => f.file_hash === file.file_hash);
    Object.assign(selectedFile, {
      ...newFileData,
      whitespaceOnlyChange: selectedFile.whitespaceOnlyChange,
    });
  },

  [types.SET_LINE_DISCUSSIONS_FOR_FILE]({ discussion, diffPositionByLineCode, hash }) {
    const { latestDiff } = this;
    const originalStartLineCode = discussion.original_position?.line_range?.start?.line_code;
    const positionType = discussion.position?.position_type;
    const discussionLineCodes = [
      discussion.line_code,
      originalStartLineCode,
      ...(discussion.line_codes || []),
    ];
    const fileHash = discussion.diff_file?.file_hash;

    const isHashTargeted = (discussionItem) =>
      discussionItem.notes && discussionItem.notes.some((note) => hash === `note_${note.id}`);

    const isTargetLine = (line) =>
      discussionLineCodes.some(
        (discussionLineCode) =>
          line.line_code === discussionLineCode &&
          isDiscussionApplicableToLine({
            discussion,
            diffPosition: diffPositionByLineCode[line.line_code],
            latestDiff,
          }),
      );

    const isExpandedDiscussion = (discussionItem) => {
      return !discussionItem.resolved || isHashTargeted(discussionItem);
    };

    const file = this.diffFiles.find((diff) => diff.file_hash === fileHash);
    // a file batch might not be loaded yet when we try to add a discussion
    if (!file) return;
    const diffLines = file[INLINE_DIFF_LINES_KEY];

    const addDiscussion = (discussions) =>
      discussions.filter(({ id }) => discussion.id !== id).concat(discussion);

    if (diffLines.length && positionType !== FILE_DIFF_POSITION_TYPE) {
      const line = diffLines.find(isTargetLine);
      // skip if none of the discussion positions matched a diff position
      if (!line) return;
      const originalDiscussions = line.discussions || [];
      if (originalDiscussions.includes(discussion)) return;
      const discussions = addDiscussion(originalDiscussions);
      Object.assign(line, {
        discussions,
        discussionsExpanded: line.discussionsExpanded || discussions.some(isExpandedDiscussion),
      });
    } else {
      const originalDiscussions = file.discussions || [];
      if (originalDiscussions.includes(discussion)) return;
      Object.assign(discussion, { expandedOnDiff: isExpandedDiscussion(discussion) });
      Object.assign(file, {
        discussions: addDiscussion(originalDiscussions),
      });
    }
  },

  [types.TOGGLE_FILE_DISCUSSION_EXPAND]({
    discussion,
    expandedOnDiff = !discussion.expandedOnDiff,
  }) {
    Object.assign(discussion, { expandedOnDiff });
    const fileHash = discussion.diff_file.file_hash;
    const diff = this.diffFiles.find((f) => f.file_hash === fileHash);
    // trigger Vue reactivity
    Object.assign(diff, { discussions: [...diff.discussions] });
  },

  [types.REMOVE_LINE_DISCUSSIONS_FOR_FILE]({ fileHash, lineCode }) {
    const selectedFile = this.diffFiles.find((f) => f.file_hash === fileHash);
    if (selectedFile) {
      updateLineInFile(selectedFile, lineCode, (line) =>
        Object.assign(line, {
          discussions: line.discussions.filter((discussion) => discussion.notes.length),
        }),
      );

      if (selectedFile.discussions && selectedFile.discussions.length) {
        selectedFile.discussions = selectedFile.discussions.filter(
          (discussion) => discussion.notes.length,
        );
      }
    }
  },

  [types.TOGGLE_LINE_DISCUSSIONS]({ fileHash, lineCode, expanded }) {
    const selectedFile = this.diffFiles.find((f) => f.file_hash === fileHash);

    updateLineInFile(selectedFile, lineCode, (line) => {
      Object.assign(line, { discussionsExpanded: expanded });
    });
  },

  [types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](expanded) {
    const lineHasDiscussion = (line) => Boolean(line.discussions?.length);
    this.diffFiles.forEach((file) => {
      const highlightedLines = file[INLINE_DIFF_LINES_KEY];
      if (highlightedLines.length) {
        const discussionLines = highlightedLines.filter(lineHasDiscussion);
        discussionLines.forEach(({ line_code }) => {
          updateLineInFile(file, line_code, (line) => {
            Object.assign(line, { discussionsExpanded: expanded });
          });
        });
      }

      const discussions = file.discussions.map((discussion) => {
        Object.assign(discussion, { expandedOnDiff: expanded });
        return discussion;
      });
      Object.assign(file, { discussions });
    });
  },

  [types.TOGGLE_FOLDER_OPEN](path) {
    this.treeEntries[path].opened = !this.treeEntries[path].opened;
  },
  [types.SET_FOLDER_OPEN]({ path, opened }) {
    this.treeEntries[path].opened = opened;
  },
  [types.TREE_ENTRY_DIFF_LOADING]({ path, loading = true }) {
    this.treeEntries[path].diffLoading = loading;
  },
  [types.SET_SHOW_TREE_LIST](showTreeList) {
    this.showTreeList = showTreeList;
  },
  [types.SET_CURRENT_DIFF_FILE](fileId) {
    this.currentDiffFileId = fileId;
  },
  [types.SET_DIFF_FILE_VIEWED]({ id, seen }) {
    this.viewedDiffFileIds = {
      ...this.viewedDiffFileIds,
      [id]: seen,
    };
  },
  [types.OPEN_DIFF_FILE_COMMENT_FORM](formData) {
    this.commentForms.push({
      ...formData,
    });
  },
  [types.UPDATE_DIFF_FILE_COMMENT_FORM](formData) {
    const { fileHash } = formData;

    this.commentForms = this.commentForms.map((form) => {
      if (form.fileHash === fileHash) {
        return {
          ...formData,
        };
      }

      return form;
    });
  },
  [types.CLOSE_DIFF_FILE_COMMENT_FORM](fileHash) {
    this.commentForms = this.commentForms.filter((form) => form.fileHash !== fileHash);
  },
  [types.SET_HIGHLIGHTED_ROW](lineCode) {
    this.highlightedRow = lineCode;
  },
  [types.SET_TREE_DATA]({ treeEntries, tree }) {
    this.treeEntries = treeEntries;
    this.tree = tree;
    this.isTreeLoaded = true;
  },
  [types.SET_RENDER_TREE_LIST](renderTreeList) {
    this.renderTreeList = renderTreeList;
  },
  [types.SET_SHOW_WHITESPACE](showWhitespace) {
    this.showWhitespace = showWhitespace;
    this.diffFiles = [];
  },
  [types.TOGGLE_FILE_FINDER_VISIBLE](visible) {
    this.fileFinderVisible = visible;
  },
  [types.REQUEST_FULL_DIFF](filePath) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = true;
  },
  [types.RECEIVE_FULL_DIFF_ERROR](filePath) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = false;
  },
  [types.RECEIVE_FULL_DIFF_SUCCESS]({ filePath }) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.isShowingFullFile = true;
    file.isLoadingFullFile = false;
  },
  [types.SET_FILE_COLLAPSED]({ filePath, collapsed, trigger = DIFF_FILE_AUTOMATIC_COLLAPSE }) {
    const file = this.diffFiles.find((f) => f.file_path === filePath);

    if (file && file.viewer) {
      if (trigger === DIFF_FILE_MANUAL_COLLAPSE) {
        file.viewer.automaticallyCollapsed = false;
        file.viewer.manuallyCollapsed = collapsed;
      } else if (trigger === DIFF_FILE_AUTOMATIC_COLLAPSE) {
        file.viewer.automaticallyCollapsed = collapsed;
        file.viewer.manuallyCollapsed = null;
      }
    }
  },
  [types.SET_FILE_FORCED_OPEN]({ filePath, forced = true }) {
    const file = this.diffFiles.find((f) => f.file_path === filePath);
    file.viewer.forceOpen = forced;
  },
  [types.SET_CURRENT_VIEW_DIFF_FILE_LINES]({ filePath, lines }) {
    const file = this.diffFiles.find((f) => f.file_path === filePath);

    file[INLINE_DIFF_LINES_KEY] = [...lines];
  },
  [types.ADD_CURRENT_VIEW_DIFF_FILE_LINES]({ filePath, line }) {
    const file = this.diffFiles.find((f) => f.file_path === filePath);

    file[INLINE_DIFF_LINES_KEY].push(line);
  },
  [types.TOGGLE_DIFF_FILE_RENDERING_MORE](filePath) {
    const file = this.diffFiles.find((f) => f.file_path === filePath);

    file.renderingLines = !file.renderingLines;
  },
  [types.SET_DIFF_FILE_VIEWER]({ filePath, viewer }) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.viewer = viewer;
  },
  [types.SET_SHOW_SUGGEST_POPOVER]() {
    this.showSuggestPopover = false;
  },
  [types.SET_FILE_BY_FILE](fileByFile) {
    this.viewDiffsFileByFile = fileByFile;
  },
  [types.SET_MR_FILE_REVIEWS](newReviews) {
    this.mrReviews = newReviews;
  },
  [types.DISABLE_VIRTUAL_SCROLLING]() {
    this.disableVirtualScroller = true;
  },
  [types.TOGGLE_FILE_COMMENT_FORM](filePath) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.hasCommentForm = !file.hasCommentForm;
  },
  [types.SET_FILE_COMMENT_FORM]({ filePath, expanded }) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file.hasCommentForm = expanded;
  },
  [types.ADD_DRAFT_TO_FILE]({ filePath, draft }) {
    const file = findDiffFile(this.diffFiles, filePath, 'file_path');

    file?.drafts.push(draft);
  },
  [types.SET_LINKED_FILE_HASH](fileHash) {
    this.linkedFileHash = fileHash;
  },
  [types.SET_COLLAPSED_STATE_FOR_ALL_FILES]({ collapsed }) {
    this.diffFiles.forEach((file) => {
      const { viewer } = file;
      if (!viewer) return;
      viewer.automaticallyCollapsed = false;
      viewer.manuallyCollapsed = collapsed;
    });
  },
};
