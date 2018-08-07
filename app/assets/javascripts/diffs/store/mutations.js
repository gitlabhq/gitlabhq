import Vue from 'vue';
import _ from 'underscore';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { findDiffFile, addLineReferences, removeMatchLine, addContextLines } from './utils';
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
    diffData.diffFiles.forEach(file => {
      if (file.parallelDiffLines) {
        file.parallelDiffLines.forEach(line => {
          // eslint-disable-next-line no-param-reassign
          delete line.text;
        });
      }

      if (file.highlightedDiffLines) {
        file.highlightedDiffLines.forEach(line => {
          // eslint-disable-next-line no-param-reassign
          if (line.left) delete line.left.text;
          // eslint-disable-next-line no-param-reassign
          if (line.right) delete line.right.text;
        });
      }

      if (file.highlightedDiffLines) {
        showingLines += file.parallelDiffLines.length;
        Object.assign(file, {
          renderIt: showingLines < 200,
          collapsed: showingLines > 2000,
        });
      }
    });

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
    // eslint-disable-next-line no-param-reassign
    state.diffFiles = state.diffFiles.map(file => ({
      ...file,
      collapsed: false,
    }));
  },
};
