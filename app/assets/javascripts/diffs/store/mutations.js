import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { sortTree } from '~/ide/stores/utils';
import {
  findDiffFile,
  addLineReferences,
  removeMatchLine,
  addContextLines,
  prepareDiffData,
  isDiscussionApplicableToLine,
  generateTreeList,
} from './utils';
import * as types from './mutation_types';

export default {
  [types.SET_BASE_CONFIG](state, options) {
    const { endpoint, projectPath } = options;
    Object.assign(state, { endpoint, projectPath });
  },

  [types.SET_LOADING](state, isLoading) {
    Object.assign(state, { isLoading });
  },

  [types.SET_DIFF_DATA](state, data) {
    const diffData = convertObjectPropsToCamelCase(data, { deep: true });
    prepareDiffData(diffData);
    const { tree, treeEntries } = generateTreeList(diffData.diffFiles);

    Object.assign(state, {
      ...diffData,
      tree: sortTree(tree),
      treeEntries,
    });
  },

  [types.RENDER_FILE](state, file) {
    Object.assign(file, {
      renderIt: true,
    });
  },

  [types.SET_MERGE_REQUEST_DIFFS](state, mergeRequestDiffs) {
    Object.assign(state, {
      mergeRequestDiffs: convertObjectPropsToCamelCase(mergeRequestDiffs, { deep: true }),
    });
  },

  [types.SET_DIFF_VIEW_TYPE](state, diffViewType) {
    Object.assign(state, { diffViewType });
  },

  [types.ADD_COMMENT_FORM_LINE](state, { lineCode }) {
    Vue.set(state.diffLineCommentForms, lineCode, true);
  },

  [types.REMOVE_COMMENT_FORM_LINE](state, { lineCode }) {
    Vue.delete(state.diffLineCommentForms, lineCode);
  },

  [types.ADD_CONTEXT_LINES](state, options) {
    const { lineNumbers, contextLines, fileHash } = options;
    const { bottom } = options.params;
    const diffFile = findDiffFile(state.diffFiles, fileHash);
    const { highlightedDiffLines, parallelDiffLines } = diffFile;

    removeMatchLine(diffFile, lineNumbers, bottom);
    const lines = addLineReferences(contextLines, lineNumbers, bottom);
    addContextLines({
      inlineLines: highlightedDiffLines,
      parallelLines: parallelDiffLines,
      contextLines: lines,
      bottom,
      lineNumbers,
    });
  },

  [types.ADD_COLLAPSED_DIFFS](state, { file, data }) {
    const normalizedData = convertObjectPropsToCamelCase(data, { deep: true });
    prepareDiffData(normalizedData);
    const [newFileData] = normalizedData.diffFiles.filter(f => f.fileHash === file.fileHash);
    const selectedFile = state.diffFiles.find(f => f.fileHash === file.fileHash);
    Object.assign(selectedFile, { ...newFileData });
  },

  [types.EXPAND_ALL_FILES](state) {
    state.diffFiles = state.diffFiles.map(file => ({
      ...file,
      collapsed: false,
    }));
  },

  [types.SET_LINE_DISCUSSIONS_FOR_FILE](state, { diffFile, discussions, diffPositionByLineCode }) {
    const { latestDiff } = state;

    discussions.forEach(discussion => {
      const discussionLineCode = discussion.line_code;
      const lineCheck = ({ lineCode }) =>
        lineCode === discussionLineCode &&
        isDiscussionApplicableToLine({
          discussion,
          diffPosition: diffPositionByLineCode[lineCode],
          latestDiff,
        });

      if (diffFile.highlightedDiffLines) {
        const line = diffFile.highlightedDiffLines.find(lineCheck);

        if (line) {
          Object.assign(line, {
            discussions: line.discussions.concat(discussion),
          });
        }
      }

      if (diffFile.parallelDiffLines) {
        const { left, right } = diffFile.parallelDiffLines.find(
          parallelLine =>
            (parallelLine.left && lineCheck(parallelLine.left)) ||
            (parallelLine.right && lineCheck(parallelLine.right)),
        );
        const line = left && left.lineCode === discussionLineCode ? left : right;

        if (line) {
          Object.assign(line, {
            discussions: line.discussions.concat(discussion),
          });
        }
      }

      if (!diffFile.parallelDiffLines || !diffFile.highlightedDiffLines) {
        Object.assign(diffFile, {
          discussions: diffFile.discussions.concat(discussion),
        });
      }
    });
  },

  [types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, { fileHash, lineCode }) {
    const selectedFile = state.diffFiles.find(f => f.fileHash === fileHash);
    if (selectedFile) {
      const targetLine = selectedFile.parallelDiffLines.find(
        line =>
          (line.left && line.left.lineCode === lineCode) ||
          (line.right && line.right.lineCode === lineCode),
      );
      if (targetLine) {
        const side = targetLine.left && targetLine.left.lineCode === lineCode ? 'left' : 'right';

        Object.assign(targetLine[side], {
          discussions: [],
        });
      }

      if (selectedFile.highlightedDiffLines) {
        const targetInlineLine = selectedFile.highlightedDiffLines.find(
          line => line.lineCode === lineCode,
        );

        if (targetInlineLine) {
          Object.assign(targetInlineLine, {
            discussions: [],
          });
        }
      }
    }
  },
  [types.TOGGLE_FOLDER_OPEN](state, path) {
    state.treeEntries[path].opened = !state.treeEntries[path].opened;
  },
  [types.TOGGLE_SHOW_TREE_LIST](state) {
    state.showTreeList = !state.showTreeList;
  },
  [types.UPDATE_CURRENT_DIFF_FILE_ID](state, fileId) {
    state.currentDiffFileId = fileId;
  },
};
