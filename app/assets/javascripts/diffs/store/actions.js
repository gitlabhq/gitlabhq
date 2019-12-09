import Vue from 'vue';
import Cookies from 'js-cookie';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { handleLocationHash, historyPushState, scrollToElement } from '~/lib/utils/common_utils';
import { mergeUrlParams, getLocationHash } from '~/lib/utils/url_utility';
import TreeWorker from '../workers/tree_worker';
import eventHub from '../../notes/event_hub';
import {
  getDiffPositionByLineCode,
  getNoteFormData,
  convertExpandLines,
  idleCallback,
  allDiscussionWrappersExpanded,
  prepareDiffData,
} from './utils';
import * as types from './mutation_types';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  MR_TREE_SHOW_KEY,
  TREE_LIST_STORAGE_KEY,
  WHITESPACE_STORAGE_KEY,
  TREE_LIST_WIDTH_STORAGE_KEY,
  OLD_LINE_KEY,
  NEW_LINE_KEY,
  TYPE_KEY,
  LEFT_LINE_KEY,
  MAX_RENDERING_DIFF_LINES,
  MAX_RENDERING_BULK_ROWS,
  MIN_RENDERING_MS,
  START_RENDERING_INDEX,
  INLINE_DIFF_LINES_KEY,
  PARALLEL_DIFF_LINES_KEY,
  DIFFS_PER_PAGE,
} from '../constants';
import { diffViewerModes } from '~/ide/constants';

export const setBaseConfig = ({ commit }, options) => {
  const {
    endpoint,
    endpointMetadata,
    endpointBatch,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
  } = options;
  commit(types.SET_BASE_CONFIG, {
    endpoint,
    endpointMetadata,
    endpointBatch,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
  });
};

export const fetchDiffFiles = ({ state, commit }) => {
  const worker = new TreeWorker();

  commit(types.SET_LOADING, true);

  worker.addEventListener('message', ({ data }) => {
    commit(types.SET_TREE_DATA, data);

    worker.terminate();
  });

  return axios
    .get(mergeUrlParams({ w: state.showWhitespace ? '0' : '1' }, state.endpoint))
    .then(res => {
      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, res.data.merge_request_diffs || []);
      commit(types.SET_DIFF_DATA, res.data);

      worker.postMessage(state.diffFiles);

      return Vue.nextTick();
    })
    .then(handleLocationHash)
    .catch(() => worker.terminate());
};

export const fetchDiffFilesBatch = ({ commit, state }) => {
  const baseUrl = `${state.endpointBatch}?per_page=${DIFFS_PER_PAGE}`;
  const url = page => (page ? `${baseUrl}&page=${page}` : baseUrl);

  commit(types.SET_BATCH_LOADING, true);

  const getBatch = page =>
    axios
      .get(url(page))
      .then(({ data: { pagination, diff_files } }) => {
        commit(types.SET_DIFF_DATA_BATCH, { diff_files });
        commit(types.SET_BATCH_LOADING, false);
        return pagination.next_page;
      })
      .then(nextPage => nextPage && getBatch(nextPage));

  return getBatch()
    .then(handleLocationHash)
    .catch(() => null);
};

export const fetchDiffFilesMeta = ({ commit, state }) => {
  const worker = new TreeWorker();

  commit(types.SET_LOADING, true);

  worker.addEventListener('message', ({ data }) => {
    commit(types.SET_TREE_DATA, data);

    worker.terminate();
  });

  return axios
    .get(state.endpointMetadata)
    .then(({ data }) => {
      const strippedData = { ...data };
      delete strippedData.diff_files;
      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, data.merge_request_diffs || []);
      commit(types.SET_DIFF_DATA, strippedData);

      prepareDiffData(data);
      worker.postMessage(data.diff_files);
    })
    .catch(() => worker.terminate());
};

export const setHighlightedRow = ({ commit }, lineCode) => {
  const fileHash = lineCode.split('_')[0];
  commit(types.SET_HIGHLIGHTED_ROW, lineCode);
  commit(types.UPDATE_CURRENT_DIFF_FILE_ID, fileHash);
};

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export const assignDiscussionsToDiff = (
  { commit, state, rootState },
  discussions = rootState.notes.discussions,
) => {
  const diffPositionByLineCode = getDiffPositionByLineCode(state.diffFiles);
  const hash = getLocationHash();

  discussions
    .filter(discussion => discussion.diff_discussion)
    .forEach(discussion => {
      commit(types.SET_LINE_DISCUSSIONS_FOR_FILE, {
        discussion,
        diffPositionByLineCode,
        hash,
      });
    });

  Vue.nextTick(() => {
    eventHub.$emit('scrollToDiscussion');
  });
};

export const removeDiscussionsFromDiff = ({ commit }, removeDiscussion) => {
  const { file_hash, line_code, id } = removeDiscussion;
  commit(types.REMOVE_LINE_DISCUSSIONS_FOR_FILE, { fileHash: file_hash, lineCode: line_code, id });
};

export const toggleLineDiscussions = ({ commit }, options) => {
  commit(types.TOGGLE_LINE_DISCUSSIONS, options);
};

export const renderFileForDiscussionId = ({ commit, rootState, state }, discussionId) => {
  const discussion = rootState.notes.discussions.find(d => d.id === discussionId);

  if (discussion && discussion.diff_file) {
    const file = state.diffFiles.find(f => f.file_hash === discussion.diff_file.file_hash);

    if (file) {
      if (!file.renderIt) {
        commit(types.RENDER_FILE, file);
      }

      if (file.viewer.collapsed) {
        eventHub.$emit(`loadCollapsedDiff/${file.file_hash}`);
        scrollToElement(document.getElementById(file.file_hash));
      } else {
        eventHub.$emit('scrollToDiscussion');
      }
    }
  }
};

export const startRenderDiffsQueue = ({ state, commit }) => {
  const checkItem = () =>
    new Promise(resolve => {
      const nextFile = state.diffFiles.find(
        file =>
          !file.renderIt &&
          (file.viewer && (!file.viewer.collapsed || !file.viewer.name === diffViewerModes.text)),
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

export const setRenderIt = ({ commit }, file) => commit(types.RENDER_FILE, file);

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
  const { endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers } = options;

  params.from_merge_request = true;

  return axios.get(endpoint, { params }).then(res => {
    const contextLines = res.data || [];

    commit(types.ADD_CONTEXT_LINES, {
      lineNumbers,
      contextLines,
      params,
      fileHash,
      isExpandDown,
      nextLineNumbers,
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

export const loadCollapsedDiff = ({ commit, getters, state }, file) =>
  axios
    .get(file.load_collapsed_diff_url, {
      params: {
        commit_id: getters.commitId,
        w: state.showWhitespace ? '0' : '1',
      },
    })
    .then(res => {
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

export const toggleFileDiscussionWrappers = ({ commit }, diff) => {
  const discussionWrappersExpanded = allDiscussionWrappersExpanded(diff);
  let linesWithDiscussions;
  if (diff.highlighted_diff_lines) {
    linesWithDiscussions = diff.highlighted_diff_lines.filter(line => line.discussions.length);
  }
  if (diff.parallel_diff_lines) {
    linesWithDiscussions = diff.parallel_diff_lines.filter(
      line =>
        (line.left && line.left.discussions.length) ||
        (line.right && line.right.discussions.length),
    );
  }

  if (linesWithDiscussions.length) {
    linesWithDiscussions.forEach(line => {
      commit(types.TOGGLE_LINE_DISCUSSIONS, {
        fileHash: diff.file_hash,
        lineCode: line.line_code,
        expanded: !discussionWrappersExpanded,
      });
    });
  }
};

export const saveDiffDiscussion = ({ state, dispatch }, { note, formData }) => {
  const postData = getNoteFormData({
    commit: state.commit,
    note,
    ...formData,
  });

  return dispatch('saveNote', postData, { root: true })
    .then(result => dispatch('updateDiscussion', result.discussion, { root: true }))
    .then(discussion => dispatch('assignDiscussionsToDiff', [discussion]))
    .then(() => dispatch('updateResolvableDiscussionsCounts', null, { root: true }))
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
};

export const toggleShowTreeList = ({ commit, state }, saving = true) => {
  commit(types.TOGGLE_SHOW_TREE_LIST);

  if (saving) {
    localStorage.setItem(MR_TREE_SHOW_KEY, state.showTreeList);
  }
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

export const setRenderTreeList = ({ commit }, renderTreeList) => {
  commit(types.SET_RENDER_TREE_LIST, renderTreeList);

  localStorage.setItem(TREE_LIST_STORAGE_KEY, renderTreeList);
};

export const setShowWhitespace = ({ commit }, { showWhitespace, pushState = false }) => {
  commit(types.SET_SHOW_WHITESPACE, showWhitespace);

  localStorage.setItem(WHITESPACE_STORAGE_KEY, showWhitespace);

  if (pushState) {
    historyPushState(mergeUrlParams({ w: showWhitespace ? '0' : '1' }, window.location.href));
  }

  eventHub.$emit('refetchDiffData');
};

export const toggleFileFinder = ({ commit }, visible) => {
  commit(types.TOGGLE_FILE_FINDER_VISIBLE, visible);
};

export const cacheTreeListWidth = (_, size) => {
  localStorage.setItem(TREE_LIST_WIDTH_STORAGE_KEY, size);
};

export const requestFullDiff = ({ commit }, filePath) => commit(types.REQUEST_FULL_DIFF, filePath);
export const receiveFullDiffSucess = ({ commit }, { filePath }) =>
  commit(types.RECEIVE_FULL_DIFF_SUCCESS, { filePath });
export const receiveFullDiffError = ({ commit }, filePath) => {
  commit(types.RECEIVE_FULL_DIFF_ERROR, filePath);
  createFlash(s__('MergeRequest|Error loading full diff. Please try again.'));
};

export const setExpandedDiffLines = ({ commit, state }, { file, data }) => {
  const expandedDiffLines = {
    highlighted_diff_lines: convertExpandLines({
      diffLines: file.highlighted_diff_lines,
      typeKey: TYPE_KEY,
      oldLineKey: OLD_LINE_KEY,
      newLineKey: NEW_LINE_KEY,
      data,
      mapLine: ({ line, oldLine, newLine }) =>
        Object.assign(line, {
          old_line: oldLine,
          new_line: newLine,
          line_code: `${file.file_hash}_${oldLine}_${newLine}`,
        }),
    }),
    parallel_diff_lines: convertExpandLines({
      diffLines: file.parallel_diff_lines,
      typeKey: [LEFT_LINE_KEY, TYPE_KEY],
      oldLineKey: [LEFT_LINE_KEY, OLD_LINE_KEY],
      newLineKey: [LEFT_LINE_KEY, NEW_LINE_KEY],
      data,
      mapLine: ({ line, oldLine, newLine }) => ({
        left: {
          ...line,
          old_line: oldLine,
          line_code: `${file.file_hash}_${oldLine}_${newLine}`,
        },
        right: {
          ...line,
          new_line: newLine,
          line_code: `${file.file_hash}_${newLine}_${oldLine}`,
        },
      }),
    }),
  };
  const currentDiffLinesKey =
    state.diffViewType === INLINE_DIFF_VIEW_TYPE ? INLINE_DIFF_LINES_KEY : PARALLEL_DIFF_LINES_KEY;
  const hiddenDiffLinesKey =
    state.diffViewType === INLINE_DIFF_VIEW_TYPE ? PARALLEL_DIFF_LINES_KEY : INLINE_DIFF_LINES_KEY;

  commit(types.SET_HIDDEN_VIEW_DIFF_FILE_LINES, {
    filePath: file.file_path,
    lines: expandedDiffLines[hiddenDiffLinesKey],
  });

  if (expandedDiffLines[currentDiffLinesKey].length > MAX_RENDERING_DIFF_LINES) {
    let index = START_RENDERING_INDEX;
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines[currentDiffLinesKey].slice(0, index),
    });
    commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);

    const idleCb = t => {
      const startIndex = index;

      while (
        t.timeRemaining() >= MIN_RENDERING_MS &&
        index !== expandedDiffLines[currentDiffLinesKey].length &&
        index - startIndex !== MAX_RENDERING_BULK_ROWS
      ) {
        const line = expandedDiffLines[currentDiffLinesKey][index];

        if (line) {
          commit(types.ADD_CURRENT_VIEW_DIFF_FILE_LINES, { filePath: file.file_path, line });
          index += 1;
        }
      }

      if (index !== expandedDiffLines[currentDiffLinesKey].length) {
        idleCallback(idleCb);
      } else {
        commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);
      }
    };

    idleCallback(idleCb);
  } else {
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines[currentDiffLinesKey],
    });
  }
};

export const fetchFullDiff = ({ dispatch }, file) =>
  axios
    .get(file.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      dispatch('receiveFullDiffSucess', { filePath: file.file_path });
      dispatch('setExpandedDiffLines', { file, data });
    })
    .catch(() => dispatch('receiveFullDiffError', file.file_path));

export const toggleFullDiff = ({ dispatch, getters, state }, filePath) => {
  const file = state.diffFiles.find(f => f.file_path === filePath);

  dispatch('requestFullDiff', filePath);

  if (file.isShowingFullFile) {
    dispatch('loadCollapsedDiff', file)
      .then(() => dispatch('assignDiscussionsToDiff', getters.getDiffFileDiscussions(file)))
      .catch(() => dispatch('receiveFullDiffError', filePath));
  } else {
    dispatch('fetchFullDiff', file);
  }
};

export const setFileCollapsed = ({ commit }, { filePath, collapsed }) =>
  commit(types.SET_FILE_COLLAPSED, { filePath, collapsed });

export const setSuggestPopoverDismissed = ({ commit, state }) =>
  axios
    .post(state.dismissEndpoint, {
      feature_name: 'suggest_popover_dismissed',
    })
    .then(() => {
      commit(types.SET_SHOW_SUGGEST_POPOVER);
    })
    .catch(() => {
      createFlash(s__('MergeRequest|Error dismissing suggestion popover. Please try again.'));
    });

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
