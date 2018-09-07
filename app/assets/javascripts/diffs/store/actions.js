import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import Cookies from 'js-cookie';
import { handleLocationHash, historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import * as types from './mutation_types';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
} from '../constants';

export const setBaseConfig = ({ commit }, options) => {
  const { endpoint, projectPath } = options;
  commit(types.SET_BASE_CONFIG, { endpoint, projectPath });
};

export const fetchDiffFiles = ({ state, commit }) => {
  commit(types.SET_LOADING, true);

  return axios
    .get(state.endpoint)
    .then(res => {
      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, res.data.merge_request_diffs || []);
      commit(types.SET_DIFF_DATA, res.data);
      return Vue.nextTick();
    })
    .then(handleLocationHash);
};

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export const assignDiscussionsToDiff = ({ state, commit }, allLineDiscussions) => {
  Object.values(allLineDiscussions).forEach(discussions => {
    if (discussions.length > 0) {
      const { fileHash } = discussions[0];
      const selectedFile = state.diffFiles.find(file => file.fileHash === fileHash);
      if (selectedFile) {
        const targetLine = selectedFile.parallelDiffLines.find(
          line =>
            (line.left && line.left.lineCode === discussions[0].line_code) ||
            (line.right && line.right.lineCode === discussions[0].line_code),
        );
        if (targetLine) {
          if (targetLine.left && targetLine.left.lineCode === discussions[0].line_code) {
            commit(types.SET_LINE_DISCUSSIONS, { line: targetLine.left, discussions });
          } else {
            commit(types.SET_LINE_DISCUSSIONS, { line: targetLine.right, discussions });
          }
        }

        if (selectedFile.highlightedDiffLines) {
          const targetInlineLine = selectedFile.highlightedDiffLines.find(
            line => line.lineCode === discussions[0].line_code,
          );

          if (targetInlineLine) {
            commit(types.SET_LINE_DISCUSSIONS, { line: targetInlineLine, discussions });
          }
        }
      }
    }
  });
};

export const removeDiscussionsFromDiff = ({ state, commit }, removeDiscussion) => {
  const { fileHash } = removeDiscussion;
  const selectedFile = state.diffFiles.find(file => file.fileHash === fileHash);

  if (selectedFile) {
    const targetLine = selectedFile.parallelDiffLines.find(
      line =>
        (line.left && line.left.lineCode === removeDiscussion.line_code) ||
        (line.right && line.right.lineCode === removeDiscussion.line_code),
    );

    if (targetLine) {
      if (targetLine.left && targetLine.left.lineCode === removeDiscussion.line_code) {
        commit(types.REMOVE_LINE_DISCUSSIONS, targetLine.left);
      } else {
        commit(types.REMOVE_LINE_DISCUSSIONS, targetLine.right);
      }
    }

    const targetInlineLine = selectedFile.highlightedDiffLines.find(
      line => line.lineCode === removeDiscussion.line_code,
    );

    if (targetInlineLine) {
      commit(types.REMOVE_LINE_DISCUSSIONS, targetInlineLine);
    }
  }
};

export const startRenderDiffsQueue = ({ state, commit }) => {
  const checkItem = () =>
    new Promise(resolve => {
      const nextFile = state.diffFiles.find(
        file => !file.renderIt && (!file.collapsed || !file.text),
      );

      if (nextFile) {
        requestAnimationFrame(() => {
          commit(types.RENDER_FILE, nextFile);
        });
        requestIdleCallback(
          () => {
            checkItem()
              .then(resolve)
              .catch(() => {});
          },
          { timeout: 1000 },
        );
      } else {
        resolve();
      }
    });

  return checkItem();
};

export const setInlineDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE);

  Cookies.set(DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: INLINE_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);
};

export const setParallelDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE);

  Cookies.set(DIFF_VIEW_COOKIE_NAME, PARALLEL_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: PARALLEL_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);
};

export const showCommentForm = ({ commit }, params) => {
  commit(types.ADD_COMMENT_FORM_LINE, params);
};

export const cancelCommentForm = ({ commit }, params) => {
  commit(types.REMOVE_COMMENT_FORM_LINE, params);
};

export const loadMoreLines = ({ commit }, options) => {
  const { endpoint, params, lineNumbers, fileHash } = options;

  params.from_merge_request = true;

  return axios.get(endpoint, { params }).then(res => {
    const contextLines = res.data || [];

    commit(types.ADD_CONTEXT_LINES, {
      lineNumbers,
      contextLines,
      params,
      fileHash,
    });
  });
};

export const loadCollapsedDiff = ({ commit }, file) =>
  axios.get(file.loadCollapsedDiffUrl).then(res => {
    commit(types.ADD_COLLAPSED_DIFFS, {
      file,
      data: res.data,
    });
  });

export const expandAllFiles = ({ commit }) => {
  commit(types.EXPAND_ALL_FILES);
};

/**
 * Toggles the file discussions after user clicked on the toggle discussions button.
 *
 * Gets the discussions for the provided diff.
 *
 * If all discussions are expanded, it will collapse all of them
 * If all discussions are collapsed, it will expand all of them
 * If some discussions are open and others closed, it will expand the closed ones.
 *
 * @param {Object} diff
 */
export const toggleFileDiscussions = ({ getters, dispatch }, diff) => {
  const discussions = getters.getDiffFileDiscussions(diff);
  const shouldCloseAll = getters.diffHasAllExpandedDiscussions(diff);
  const shouldExpandAll = getters.diffHasAllCollpasedDiscussions(diff);

  discussions.forEach(discussion => {
    const data = { discussionId: discussion.id };

    if (shouldCloseAll) {
      dispatch('collapseDiscussion', data, { root: true });
    } else if (shouldExpandAll || (!shouldCloseAll && !shouldExpandAll && !discussion.expanded)) {
      dispatch('expandDiscussion', data, { root: true });
    }
  });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
