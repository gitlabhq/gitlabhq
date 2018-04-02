import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as utils from './utils';
import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpoint });
  },

  [types.SET_LOADING](state, isLoading) {
    Object.assign(state, { isLoading });
  },

  [types.SET_DIFF_FILES](state, diffFiles) {
    Object.assign(state, {
      diffFiles: convertObjectPropsToCamelCase(diffFiles, {
        deep: true,
      }),
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
    const diffFile = utils.findDiffFile(state.diffFiles, fileHash);
    const { highlightedDiffLines, parallelDiffLines } = diffFile;

    utils.removeMatchLine(diffFile, lineNumbers, bottom);
    const lines = utils.addLineReferences(contextLines, lineNumbers, bottom);
    utils.addContextLines({
      inlineLines: highlightedDiffLines,
      parallelLines: parallelDiffLines,
      contextLines: lines,
      bottom,
      lineNumbers,
    });
  },
};
