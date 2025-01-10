import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  INLINE_DIFF_LINES_KEY,
  EXPANDED_LINE_TYPE,
  FILE_DIFF_POSITION_TYPE,
} from '../constants';
import * as types from './mutation_types';
import {
  findDiffFile,
  addLineReferences,
  removeMatchLine,
  addContextLines,
  prepareDiffData,
  isDiscussionApplicableToLine,
  updateLineInFile,
  markTreeEntriesLoaded,
} from './utils';

function updateDiffFilesInState(state, files) {
  return Object.assign(state, { diffFiles: files });
}

export default {
  [types.SET_BASE_CONFIG](state, options) {
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
    Object.assign(state, {
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

  [types.SET_LOADING](state, isLoading) {
    Object.assign(state, { isLoading });
  },

  [types.SET_BATCH_LOADING_STATE](state, batchLoadingState) {
    Object.assign(state, { batchLoadingState });
  },

  [types.SET_RETRIEVING_BATCHES](state, retrievingBatches) {
    Object.assign(state, { retrievingBatches });
  },

  [types.SET_DIFF_FILES](state, files) {
    updateDiffFilesInState(state, files);
  },

  [types.SET_DIFF_METADATA](state, data) {
    Object.assign(state, {
      ...convertObjectPropsToCamelCase(data),
    });
  },

  [types.SET_DIFF_DATA_BATCH](state, { diff_files: diffFiles, updatePosition = true }) {
    Object.assign(state, {
      diffFiles: prepareDiffData({
        diff: { diff_files: diffFiles },
        priorFiles: state.diffFiles,
        // when a linked file is added to diffs its position may be incorrect since it's loaded out of order
        // we need to ensure when we load it in batched request it updates it position
        updatePosition,
      }),
      treeEntries: markTreeEntriesLoaded({
        priorEntries: state.treeEntries,
        loadedFiles: diffFiles,
      }),
    });
  },

  [types.SET_DIFF_TREE_ENTRY](state, diffFile) {
    Object.assign(state, {
      treeEntries: markTreeEntriesLoaded({
        priorEntries: state.treeEntries,
        loadedFiles: [diffFile],
      }),
    });
  },

  [types.SET_COVERAGE_DATA](state, coverageFiles) {
    Object.assign(state, { coverageFiles, coverageLoaded: true });
  },

  [types.SET_MERGE_REQUEST_DIFFS](state, mergeRequestDiffs) {
    Object.assign(state, {
      mergeRequestDiffs,
    });
  },

  [types.SET_DIFF_VIEW_TYPE](state, diffViewType) {
    Object.assign(state, { diffViewType });
  },

  [types.TOGGLE_LINE_HAS_FORM](state, { lineCode, fileHash, hasForm }) {
    const diffFile = state.diffFiles.find((f) => f.file_hash === fileHash);

    if (!diffFile) return;

    diffFile[INLINE_DIFF_LINES_KEY].find((l) => l.line_code === lineCode).hasForm = hasForm;
  },

  [types.ADD_CONTEXT_LINES](state, options) {
    const { lineNumbers, contextLines, fileHash, isExpandDown, nextLineNumbers } = options;
    const { bottom } = options.params;
    const diffFile = findDiffFile(state.diffFiles, fileHash);

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

  [types.ADD_COLLAPSED_DIFFS](state, { file, data }) {
    const files = prepareDiffData({ diff: data });
    const [newFileData] = files.filter((f) => f.file_hash === file.file_hash);
    const selectedFile = state.diffFiles.find((f) => f.file_hash === file.file_hash);
    Object.assign(selectedFile, {
      ...newFileData,
      whitespaceOnlyChange: selectedFile.whitespaceOnlyChange,
    });
  },

  [types.SET_LINE_DISCUSSIONS_FOR_FILE](state, { discussion, diffPositionByLineCode, hash }) {
    const { latestDiff } = state;
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

    const file = state.diffFiles.find((diff) => diff.file_hash === fileHash);
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

  [types.TOGGLE_FILE_DISCUSSION_EXPAND](
    state,
    { discussion, expandedOnDiff = !discussion.expandedOnDiff },
  ) {
    Object.assign(discussion, { expandedOnDiff });
    const fileHash = discussion.diff_file.file_hash;
    const diff = state.diffFiles.find((f) => f.file_hash === fileHash);
    // trigger Vue reactivity
    Object.assign(diff, { discussions: [...diff.discussions] });
  },

  [types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, { fileHash, lineCode }) {
    const selectedFile = state.diffFiles.find((f) => f.file_hash === fileHash);
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

  [types.TOGGLE_LINE_DISCUSSIONS](state, { fileHash, lineCode, expanded }) {
    const selectedFile = state.diffFiles.find((f) => f.file_hash === fileHash);

    updateLineInFile(selectedFile, lineCode, (line) => {
      Object.assign(line, { discussionsExpanded: expanded });
    });
  },

  [types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](state, expanded) {
    const lineHasDiscussion = (line) => Boolean(line.discussions?.length);
    state.diffFiles.forEach((file) => {
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

  [types.TOGGLE_FOLDER_OPEN](state, path) {
    state.treeEntries[path].opened = !state.treeEntries[path].opened;
  },
  [types.SET_FOLDER_OPEN](state, { path, opened }) {
    state.treeEntries[path].opened = opened;
  },
  [types.TREE_ENTRY_DIFF_LOADING](state, { path, loading = true }) {
    state.treeEntries[path].diffLoading = loading;
  },
  [types.SET_SHOW_TREE_LIST](state, showTreeList) {
    state.showTreeList = showTreeList;
  },
  [types.SET_CURRENT_DIFF_FILE](state, fileId) {
    state.currentDiffFileId = fileId;
  },
  [types.SET_DIFF_FILE_VIEWED](state, { id, seen }) {
    state.viewedDiffFileIds = {
      ...state.viewedDiffFileIds,
      [id]: seen,
    };
  },
  [types.OPEN_DIFF_FILE_COMMENT_FORM](state, formData) {
    state.commentForms.push({
      ...formData,
    });
  },
  [types.UPDATE_DIFF_FILE_COMMENT_FORM](state, formData) {
    const { fileHash } = formData;

    state.commentForms = state.commentForms.map((form) => {
      if (form.fileHash === fileHash) {
        return {
          ...formData,
        };
      }

      return form;
    });
  },
  [types.CLOSE_DIFF_FILE_COMMENT_FORM](state, fileHash) {
    state.commentForms = state.commentForms.filter((form) => form.fileHash !== fileHash);
  },
  [types.SET_HIGHLIGHTED_ROW](state, lineCode) {
    state.highlightedRow = lineCode;
  },
  [types.SET_TREE_DATA](state, { treeEntries, tree }) {
    state.treeEntries = treeEntries;
    state.tree = tree;
    state.isTreeLoaded = true;
  },
  [types.SET_RENDER_TREE_LIST](state, renderTreeList) {
    state.renderTreeList = renderTreeList;
  },
  [types.SET_SHOW_WHITESPACE](state, showWhitespace) {
    state.showWhitespace = showWhitespace;
    state.diffFiles = [];
  },
  [types.TOGGLE_FILE_FINDER_VISIBLE](state, visible) {
    state.fileFinderVisible = visible;
  },
  [types.REQUEST_FULL_DIFF](state, filePath) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = true;
  },
  [types.RECEIVE_FULL_DIFF_ERROR](state, filePath) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = false;
  },
  [types.RECEIVE_FULL_DIFF_SUCCESS](state, { filePath }) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isShowingFullFile = true;
    file.isLoadingFullFile = false;
  },
  [types.SET_FILE_COLLAPSED](
    state,
    { filePath, collapsed, trigger = DIFF_FILE_AUTOMATIC_COLLAPSE },
  ) {
    const file = state.diffFiles.find((f) => f.file_path === filePath);

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
  [types.SET_FILE_FORCED_OPEN](state, { filePath, forced = true }) {
    const file = state.diffFiles.find((f) => f.file_path === filePath);
    file.viewer.forceOpen = forced;
  },
  [types.SET_CURRENT_VIEW_DIFF_FILE_LINES](state, { filePath, lines }) {
    const file = state.diffFiles.find((f) => f.file_path === filePath);

    file[INLINE_DIFF_LINES_KEY] = lines;
  },
  [types.ADD_CURRENT_VIEW_DIFF_FILE_LINES](state, { filePath, line }) {
    const file = state.diffFiles.find((f) => f.file_path === filePath);

    file[INLINE_DIFF_LINES_KEY].push(line);
  },
  [types.TOGGLE_DIFF_FILE_RENDERING_MORE](state, filePath) {
    const file = state.diffFiles.find((f) => f.file_path === filePath);

    file.renderingLines = !file.renderingLines;
  },
  [types.SET_DIFF_FILE_VIEWER](state, { filePath, viewer }) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.viewer = viewer;
  },
  [types.SET_SHOW_SUGGEST_POPOVER](state) {
    state.showSuggestPopover = false;
  },
  [types.SET_FILE_BY_FILE](state, fileByFile) {
    state.viewDiffsFileByFile = fileByFile;
  },
  [types.SET_MR_FILE_REVIEWS](state, newReviews) {
    state.mrReviews = newReviews;
  },
  [types.DISABLE_VIRTUAL_SCROLLING](state) {
    state.disableVirtualScroller = true;
  },
  [types.TOGGLE_FILE_COMMENT_FORM](state, filePath) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.hasCommentForm = !file.hasCommentForm;
  },
  [types.SET_FILE_COMMENT_FORM](state, { filePath, expanded }) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.hasCommentForm = expanded;
  },
  [types.ADD_DRAFT_TO_FILE](state, { filePath, draft }) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file?.drafts.push(draft);
  },
  [types.SET_LINKED_FILE_HASH](state, fileHash) {
    state.linkedFileHash = fileHash;
  },
  [types.SET_COLLAPSED_STATE_FOR_ALL_FILES](state, { collapsed }) {
    state.diffFiles.forEach((file) => {
      const { viewer } = file;
      if (!viewer) return;
      viewer.automaticallyCollapsed = false;
      viewer.manuallyCollapsed = collapsed;
    });
  },
};
