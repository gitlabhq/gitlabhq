import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  INLINE_DIFF_LINES_KEY,
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
} from './utils';

function updateDiffFilesInState(state, files) {
  return Object.assign(state, { diffFiles: files });
}

function renderFile(file) {
  Object.assign(file, {
    renderIt: true,
  });
}

export default {
  [types.SET_BASE_CONFIG](state, options) {
    const {
      endpoint,
      endpointMetadata,
      endpointBatch,
      endpointCoverage,
      endpointUpdateUser,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
      defaultSuggestionCommitMessage,
      viewDiffsFileByFile,
      mrReviews,
    } = options;
    Object.assign(state, {
      endpoint,
      endpointMetadata,
      endpointBatch,
      endpointCoverage,
      endpointUpdateUser,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
      defaultSuggestionCommitMessage,
      viewDiffsFileByFile,
      mrReviews,
    });
  },

  [types.SET_LOADING](state, isLoading) {
    Object.assign(state, { isLoading });
  },

  [types.SET_BATCH_LOADING](state, isBatchLoading) {
    Object.assign(state, { isBatchLoading });
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

  [types.SET_DIFF_DATA_BATCH](state, data) {
    state.diffFiles = prepareDiffData({
      diff: data,
      priorFiles: state.diffFiles,
    });
  },

  [types.SET_COVERAGE_DATA](state, coverageFiles) {
    Object.assign(state, { coverageFiles });
  },

  [types.RENDER_FILE](state, file) {
    renderFile(file);
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
    Object.assign(selectedFile, { ...newFileData });
  },

  [types.SET_LINE_DISCUSSIONS_FOR_FILE](state, { discussion, diffPositionByLineCode, hash }) {
    const { latestDiff } = state;

    const originalStartLineCode = discussion.original_position?.line_range?.start?.line_code;
    const discussionLineCodes = [
      discussion.line_code,
      originalStartLineCode,
      ...(discussion.line_codes || []),
    ];
    const fileHash = discussion.diff_file.file_hash;
    const lineCheck = (line) =>
      discussionLineCodes.some(
        (discussionLineCode) =>
          line.line_code === discussionLineCode &&
          isDiscussionApplicableToLine({
            discussion,
            diffPosition: diffPositionByLineCode[line.line_code],
            latestDiff,
          }),
      );
    const mapDiscussions = (line, extraCheck = () => true) => ({
      ...line,
      discussions: extraCheck()
        ? line.discussions &&
          line.discussions
            .filter(() => !line.discussions.some(({ id }) => discussion.id === id))
            .concat(lineCheck(line) ? discussion : line.discussions)
        : [],
    });

    const setDiscussionsExpanded = (line) => {
      const isLineNoteTargeted =
        line.discussions &&
        line.discussions.some(
          (disc) => disc.notes && disc.notes.find((note) => hash === `note_${note.id}`),
        );

      return {
        ...line,
        discussionsExpanded:
          line.discussions && line.discussions.length
            ? line.discussions.some((disc) => !disc.resolved) || isLineNoteTargeted
            : false,
      };
    };

    state.diffFiles.forEach((file) => {
      if (file.file_hash === fileHash) {
        if (file[INLINE_DIFF_LINES_KEY].length) {
          file[INLINE_DIFF_LINES_KEY].forEach((line) => {
            Object.assign(
              line,
              setDiscussionsExpanded(lineCheck(line) ? mapDiscussions(line) : line),
            );
          });
        }

        if (!file[INLINE_DIFF_LINES_KEY].length) {
          const newDiscussions = (file.discussions || [])
            .filter((d) => d.id !== discussion.id)
            .concat(discussion);

          Object.assign(file, {
            discussions: newDiscussions,
          });
        }
      }
    });
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

  [types.TOGGLE_FOLDER_OPEN](state, path) {
    state.treeEntries[path].opened = !state.treeEntries[path].opened;
  },
  [types.SET_SHOW_TREE_LIST](state, showTreeList) {
    state.showTreeList = showTreeList;
  },
  [types.VIEW_DIFF_FILE](state, fileId) {
    state.currentDiffFileId = fileId;
    Vue.set(state.viewedDiffFileIds, fileId, true);
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

    if (file && !collapsed) {
      renderFile(file);
    }
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
};
