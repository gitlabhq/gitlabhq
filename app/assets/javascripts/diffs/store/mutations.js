import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as utils from './utils';
import * as types from './mutation_types';
import { COMMENT_FORM_TYPE, PARALLEL_DIFF_VIEW_TYPE, LINE_POSITION_LEFT } from '../constants';

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

  [types.ADD_COMMENT_FORM_LINE](state, params) {
    const { lineCode } = params;
    let linePosition = params.linePosition;

    if (!linePosition) {
      throw new Error('you should not be here. I expect a line position');
      return;
    }

    // Always render context line comment form on the left side in parallel view
    if (state.diffViewType === PARALLEL_DIFF_VIEW_TYPE && window.TODO) {
      linePosition = LINE_POSITION_LEFT;
    }

    // We add forms as another diff line so they have to have a unique id
    // We later use this id to remove the form from diff lines
    const id = `${lineCode}_CommentForm_${linePosition || ''}`;

    // Unique comment form object as a diff line
    const formObj = {
      id,
      type: COMMENT_FORM_TYPE,
    };

    if (!state.diffLineCommentForms[lineCode]) {
      Vue.set(state.diffLineCommentForms, lineCode, { linePosition: {} });
    }

    Vue.set(state.diffLineCommentForms[lineCode], linePosition, formObj);
  },

  [types.REMOVE_COMMENT_FORM_LINE](state, { lineCode, linePosition }) {
    if (linePosition) {
      Vue.set(state.diffLineCommentForms[lineCode], linePosition, null);
    } else {
      Vue.set(state.diffLineCommentForms, lineCode, null);
    }
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
