import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import Cookies from 'js-cookie';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { handleLocationHash, historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, getLocationHash } from '~/lib/utils/url_utility';
import { getDiffPositionByLineCode, getNoteFormData } from './utils';
import * as types from './mutation_types';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  MR_TREE_SHOW_KEY,
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

export const setHighlightedRow = ({ commit }, lineCode) => {
  commit(types.SET_HIGHLIGHTED_ROW, lineCode);
};

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export const assignDiscussionsToDiff = (
  { commit, state, rootState },
  discussions = rootState.notes.discussions,
) => {
  const diffPositionByLineCode = getDiffPositionByLineCode(state.diffFiles);

  discussions
    .filter(discussion => discussion.diff_discussion)
    .forEach(discussion => {
      commit(types.SET_LINE_DISCUSSIONS_FOR_FILE, {
        discussion,
        diffPositionByLineCode,
      });
    });
};

export const removeDiscussionsFromDiff = ({ commit }, removeDiscussion) => {
  const { file_hash, line_code, id } = removeDiscussion;
  commit(types.REMOVE_LINE_DISCUSSIONS_FOR_FILE, { fileHash: file_hash, lineCode: line_code, id });
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

export const showCommentForm = ({ commit }, { lineCode, fileHash }) => {
  commit(types.TOGGLE_LINE_HAS_FORM, { lineCode, fileHash, hasForm: true });
};

export const cancelCommentForm = ({ commit }, { lineCode, fileHash }) => {
  commit(types.TOGGLE_LINE_HAS_FORM, { lineCode, fileHash, hasForm: false });
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

export const scrollToLineIfNeededInline = (_, line) => {
  const hash = getLocationHash();

  if (hash && line.line_code === hash) {
    handleLocationHash();
  }
};

export const scrollToLineIfNeededParallel = (_, line) => {
  const hash = getLocationHash();

  if (
    hash &&
    ((line.left && line.left.line_code === hash) || (line.right && line.right.line_code === hash))
  ) {
    handleLocationHash();
  }
};

export const loadCollapsedDiff = ({ commit }, file) =>
  axios.get(file.load_collapsed_diff_url).then(res => {
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
  const shouldExpandAll = getters.diffHasAllCollapsedDiscussions(diff);

  discussions.forEach(discussion => {
    const data = { discussionId: discussion.id };

    if (shouldCloseAll) {
      dispatch('collapseDiscussion', data, { root: true });
    } else if (shouldExpandAll || (!shouldCloseAll && !shouldExpandAll && !discussion.expanded)) {
      dispatch('expandDiscussion', data, { root: true });
    }
  });
};

export const saveDiffDiscussion = ({ dispatch }, { note, formData }) => {
  const postData = getNoteFormData({
    note,
    ...formData,
  });

  return dispatch('saveNote', postData, { root: true })
    .then(result => dispatch('updateDiscussion', result.discussion, { root: true }))
    .then(discussion => dispatch('assignDiscussionsToDiff', [discussion]))
    .then(() => dispatch('updateResolvableDiscussonsCounts', null, { root: true }))
    .then(() => dispatch('closeDiffFileCommentForm', formData.diffFile.file_hash))
    .catch(() => createFlash(s__('MergeRequests|Saving the comment failed')));
};

export const toggleTreeOpen = ({ commit }, path) => {
  commit(types.TOGGLE_FOLDER_OPEN, path);
};

export const scrollToFile = ({ state, commit }, path) => {
  const { fileHash } = state.treeEntries[path];
  document.location.hash = fileHash;

  commit(types.UPDATE_CURRENT_DIFF_FILE_ID, fileHash);

  setTimeout(() => commit(types.UPDATE_CURRENT_DIFF_FILE_ID, ''), 1000);
};

export const toggleShowTreeList = ({ commit, state }) => {
  commit(types.TOGGLE_SHOW_TREE_LIST);
  localStorage.setItem(MR_TREE_SHOW_KEY, state.showTreeList);
};

export const openDiffFileCommentForm = ({ commit, getters }, formData) => {
  const form = getters.getCommentFormForDiffFile(formData.fileHash);

  if (form) {
    commit(types.UPDATE_DIFF_FILE_COMMENT_FORM, formData);
  } else {
    commit(types.OPEN_DIFF_FILE_COMMENT_FORM, formData);
  }
};

export const closeDiffFileCommentForm = ({ commit }, fileHash) => {
  commit(types.CLOSE_DIFF_FILE_COMMENT_FORM, fileHash);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
