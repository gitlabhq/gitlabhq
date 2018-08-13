import Vue from 'vue';
import _ from 'underscore';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { findDiffFile, addLineReferences, removeMatchLine, addContextLines } from './utils';
import { LINES_TO_BE_RENDERED_DIRECTLY, MAX_LINES_TO_BE_RENDERED } from '../constants';
import { trimFirstCharOfLineContent } from '../store/utils';
import { LINES_TO_BE_RENDERED_DIRECTLY, MAX_LINES_TO_BE_RENDERED } from '../constants';
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
    let showingLines = 0;
    const filesLength = diffData.diffFiles.length;
    let i;
    for (i = 0; i < filesLength; i += 1) {
      const file = diffData.diffFiles[i];
      if (file.parallelDiffLines) {
        const linesLength = file.parallelDiffLines.length;
        let u = 0;
        for (u = 0; u < linesLength; u += 1) {
          const line = file.parallelDiffLines[u];
          if (line.left) delete line.left.text;
          if (line.right) delete line.right.text;
        }
      }

      if (file.highlightedDiffLines) {
        const linesLength = file.highlightedDiffLines.length;
        let u;
        for (u = 0; u < linesLength; u += 1) {
          const line = file.highlightedDiffLines[u];
          delete line.text;
        }
      }

      if (file.highlightedDiffLines) {
        showingLines += file.parallelDiffLines.length;
      }
      Object.assign(file, {
        renderIt: showingLines < LINES_TO_BE_RENDERED_DIRECTLY,
        collapsed: file.text && showingLines > MAX_LINES_TO_BE_RENDERED,
      });
    }

    Object.assign(state, {
      ...diffData,
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
    const [newFileData] = normalizedData.diffFiles.filter(f => f.fileHash === file.fileHash);

    if (newFileData) {
      const index = _.findIndex(state.diffFiles, f => f.fileHash === file.fileHash);
      state.diffFiles.splice(index, 1, newFileData);
    }
  },

  [types.EXPAND_ALL_FILES](state) {
    state.diffFiles = state.diffFiles.map(file => ({
      ...file,
      collapsed: false,
    }));
  },
};
