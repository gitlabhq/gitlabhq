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

  [types.SET_LINE_DISCUSSIONS_FOR_FILE](state, { discussion, diffPositionByLineCode }) {
    const { latestDiff } = state;

    const discussionLineCode = discussion.line_code;
    const fileHash = discussion.diff_file.file_hash;
    const lineCheck = ({ lineCode }) =>
      lineCode === discussionLineCode &&
      isDiscussionApplicableToLine({
        discussion,
        diffPosition: diffPositionByLineCode[lineCode],
        latestDiff,
      });

    state.diffFiles = state.diffFiles.map(diffFile => {
      if (diffFile.fileHash === fileHash) {
        const file = { ...diffFile };

        if (file.highlightedDiffLines) {
          file.highlightedDiffLines = file.highlightedDiffLines.map(line => {
            if (lineCheck(line)) {
              return {
                ...line,
                discussions: line.discussions.concat(discussion),
              };
            }

            return line;
          });
        }

        if (file.parallelDiffLines) {
          file.parallelDiffLines = file.parallelDiffLines.map(line => {
            const left = line.left && lineCheck(line.left);
            const right = line.right && lineCheck(line.right);

            if (left || right) {
              return {
                left: {
                  ...line.left,
                  discussions: left ? line.left.discussions.concat(discussion) : [],
                },
                right: {
                  ...line.right,
                  discussions: right && !left ? line.right.discussions.concat(discussion) : [],
                },
              };
            }

            return line;
          });
        }

        if (!file.parallelDiffLines || !file.highlightedDiffLines) {
          file.discussions = file.discussions.concat(discussion);
        }

        return file;
      }

      return diffFile;
    });
  },

  [types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, { fileHash, lineCode, id }) {
    const selectedFile = state.diffFiles.find(f => f.fileHash === fileHash);
    if (selectedFile) {
      if (selectedFile.parallelDiffLines) {
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

      if (selectedFile.discussions && selectedFile.discussions.length) {
        selectedFile.discussions = selectedFile.discussions.filter(
          discussion => discussion.id !== id,
        );
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
  [types.OPEN_DIFF_FILE_COMMENT_FORM](state, formData) {
    state.commentForms.push({
      ...formData,
    });
  },
  [types.UPDATE_DIFF_FILE_COMMENT_FORM](state, formData) {
    const { fileHash } = formData;

    state.commentForms = state.commentForms.map(form => {
      if (form.fileHash === fileHash) {
        return {
          ...formData,
        };
      }

      return form;
    });
  },
  [types.CLOSE_DIFF_FILE_COMMENT_FORM](state, fileHash) {
    state.commentForms = state.commentForms.filter(form => form.fileHash !== fileHash);
  },
};
