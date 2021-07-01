import Cookies from 'js-cookie';
import Vue from 'vue';
import api from '~/api';
import createFlash from '~/flash';
import { diffViewerModes } from '~/ide/constants';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash, historyPushState, scrollToElement } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { mergeUrlParams, getLocationHash } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import notesEventHub from '../../notes/event_hub';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  MR_TREE_SHOW_KEY,
  TREE_LIST_STORAGE_KEY,
  TREE_LIST_WIDTH_STORAGE_KEY,
  OLD_LINE_KEY,
  NEW_LINE_KEY,
  TYPE_KEY,
  MAX_RENDERING_DIFF_LINES,
  MAX_RENDERING_BULK_ROWS,
  MIN_RENDERING_MS,
  START_RENDERING_INDEX,
  INLINE_DIFF_LINES_KEY,
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  EVT_PERF_MARK_FILE_TREE_START,
  EVT_PERF_MARK_FILE_TREE_END,
  EVT_PERF_MARK_DIFF_FILES_START,
  DIFF_VIEW_FILE_BY_FILE,
  DIFF_VIEW_ALL_FILES,
  DIFF_FILE_BY_FILE_COOKIE_NAME,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_CLICK_FILE_BROWSER_SETTING,
  TRACKING_FILE_BROWSER_TREE,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_CLICK_WHITESPACE_SETTING,
  TRACKING_WHITESPACE_SHOW,
  TRACKING_WHITESPACE_HIDE,
  TRACKING_CLICK_SINGLE_FILE_SETTING,
  TRACKING_SINGLE_FILE_MODE,
  TRACKING_MULTIPLE_FILES_MODE,
} from '../constants';
import eventHub from '../event_hub';
import { isCollapsed } from '../utils/diff_file';
import { markFileReview, setReviewsForMergeRequest } from '../utils/file_reviews';
import { getDerivedMergeRequestInformation } from '../utils/merge_request';
import TreeWorker from '../workers/tree_worker';
import * as types from './mutation_types';
import {
  getDiffPositionByLineCode,
  getNoteFormData,
  convertExpandLines,
  idleCallback,
  allDiscussionWrappersExpanded,
  prepareLineForRenamedFile,
} from './utils';

export const setBaseConfig = ({ commit }, options) => {
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
  commit(types.SET_BASE_CONFIG, {
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
};

export const fetchDiffFilesBatch = ({ commit, state, dispatch }) => {
  let perPage = state.viewDiffsFileByFile ? 1 : 5;
  let increaseAmount = 1.4;
  const startPage = 0;
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const urlParams = {
    w: state.showWhitespace ? '0' : '1',
    view: 'inline',
  };
  const hash = window.location.hash.replace('#', '').split('diff-content-').pop();
  let totalLoaded = 0;
  let scrolledVirtualScroller = false;

  commit(types.SET_BATCH_LOADING, true);
  commit(types.SET_RETRIEVING_BATCHES, true);
  eventHub.$emit(EVT_PERF_MARK_DIFF_FILES_START);

  const getBatch = (page = startPage) =>
    axios
      .get(mergeUrlParams({ ...urlParams, page, per_page: perPage }, state.endpointBatch))
      .then(({ data: { pagination, diff_files } }) => {
        totalLoaded += diff_files.length;

        commit(types.SET_DIFF_DATA_BATCH, { diff_files });
        commit(types.SET_BATCH_LOADING, false);

        if (window.gon?.features?.diffsVirtualScrolling && !scrolledVirtualScroller) {
          const index = state.diffFiles.findIndex(
            (f) =>
              f.file_hash === hash || f[INLINE_DIFF_LINES_KEY].find((l) => l.line_code === hash),
          );

          if (index >= 0) {
            eventHub.$emit('scrollToIndex', index);
            scrolledVirtualScroller = true;
          }
        }

        if (!isNoteLink && !state.currentDiffFileId) {
          commit(types.VIEW_DIFF_FILE, diff_files[0].file_hash);
        }

        if (isNoteLink) {
          dispatch('setCurrentDiffFileIdFromNote', id.split('_').pop());
        }

        if (totalLoaded === pagination.total_pages || pagination.total_pages === null) {
          commit(types.SET_RETRIEVING_BATCHES, false);

          // We need to check that the currentDiffFileId points to a file that exists
          if (
            state.currentDiffFileId &&
            !state.diffFiles.some((f) => f.file_hash === state.currentDiffFileId) &&
            !isNoteLink
          ) {
            commit(types.VIEW_DIFF_FILE, state.diffFiles[0].file_hash);
          }

          if (state.diffFiles?.length) {
            // eslint-disable-next-line promise/catch-or-return,promise/no-nesting
            import('~/code_navigation').then((m) =>
              m.default({
                blobs: state.diffFiles
                  .filter((f) => f.code_navigation_path)
                  .map((f) => ({
                    path: f.new_path,
                    codeNavigationPath: f.code_navigation_path,
                  })),
                definitionPathPrefix: state.definitionPathPrefix,
              }),
            );
          }

          return null;
        }

        const nextPage = page + perPage;
        perPage = Math.min(Math.ceil(perPage * increaseAmount), 30);
        increaseAmount = Math.min(increaseAmount + 0.2, 2);

        return nextPage;
      })
      .then((nextPage) => {
        dispatch('startRenderDiffsQueue');

        if (nextPage) {
          return getBatch(nextPage);
        }

        return null;
      })
      .catch(() => commit(types.SET_RETRIEVING_BATCHES, false));

  return getBatch()
    .then(() => !window.gon?.features?.diffsVirtualScrolling && handleLocationHash())
    .catch(() => null);
};

export const fetchDiffFilesMeta = ({ commit, state }) => {
  const worker = new TreeWorker();
  const urlParams = {
    view: 'inline',
  };

  commit(types.SET_LOADING, true);
  eventHub.$emit(EVT_PERF_MARK_FILE_TREE_START);

  worker.addEventListener('message', ({ data }) => {
    commit(types.SET_TREE_DATA, data);
    eventHub.$emit(EVT_PERF_MARK_FILE_TREE_END);

    worker.terminate();
  });

  return axios
    .get(mergeUrlParams(urlParams, state.endpointMetadata))
    .then(({ data }) => {
      const strippedData = { ...data };
      delete strippedData.diff_files;

      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, data.merge_request_diffs || []);
      commit(types.SET_DIFF_METADATA, strippedData);

      worker.postMessage(data.diff_files);

      return data;
    })
    .catch(() => worker.terminate());
};

export const fetchCoverageFiles = ({ commit, state }) => {
  const coveragePoll = new Poll({
    resource: {
      getCoverageReports: (endpoint) => axios.get(endpoint),
    },
    data: state.endpointCoverage,
    method: 'getCoverageReports',
    successCallback: ({ status, data }) => {
      if (status === httpStatusCodes.OK) {
        commit(types.SET_COVERAGE_DATA, data);

        coveragePoll.stop();
      }
    },
    errorCallback: () =>
      createFlash({
        message: __('Something went wrong on our end. Please try again!'),
      }),
  });

  coveragePoll.makeRequest();
};

export const setHighlightedRow = ({ commit }, lineCode) => {
  const fileHash = lineCode.split('_')[0];
  commit(types.SET_HIGHLIGHTED_ROW, lineCode);
  commit(types.VIEW_DIFF_FILE, fileHash);

  handleLocationHash();
};

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export const assignDiscussionsToDiff = (
  { commit, state, rootState, dispatch },
  discussions = rootState.notes.discussions,
) => {
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const diffPositionByLineCode = getDiffPositionByLineCode(state.diffFiles);
  const hash = getLocationHash();

  discussions
    .filter((discussion) => discussion.diff_discussion)
    .forEach((discussion) => {
      commit(types.SET_LINE_DISCUSSIONS_FOR_FILE, {
        discussion,
        diffPositionByLineCode,
        hash,
      });
    });

  if (isNoteLink) {
    dispatch('setCurrentDiffFileIdFromNote', id.split('_').pop());
  }

  Vue.nextTick(() => {
    notesEventHub.$emit('scrollToDiscussion');
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
  const discussion = rootState.notes.discussions.find((d) => d.id === discussionId);

  if (discussion && discussion.diff_file) {
    const file = state.diffFiles.find((f) => f.file_hash === discussion.diff_file.file_hash);

    if (file) {
      if (!file.renderIt) {
        commit(types.RENDER_FILE, file);
      }

      if (file.viewer.automaticallyCollapsed) {
        notesEventHub.$emit(`loadCollapsedDiff/${file.file_hash}`);
        scrollToElement(document.getElementById(file.file_hash));
      } else if (file.viewer.manuallyCollapsed) {
        commit(types.SET_FILE_COLLAPSED, {
          filePath: file.file_path,
          collapsed: false,
          trigger: DIFF_FILE_AUTOMATIC_COLLAPSE,
        });
        notesEventHub.$emit('scrollToDiscussion');
      } else {
        notesEventHub.$emit('scrollToDiscussion');
      }
    }
  }
};

export const startRenderDiffsQueue = ({ state, commit }) => {
  const diffFilesToRender = state.diffFiles.filter(
    (file) =>
      !file.renderIt &&
      file.viewer &&
      (!isCollapsed(file) || file.viewer.name !== diffViewerModes.text),
  );
  let currentDiffFileIndex = 0;

  const checkItem = () => {
    const nextFile = diffFilesToRender[currentDiffFileIndex];

    if (nextFile) {
      let retryCount = 0;
      currentDiffFileIndex += 1;
      commit(types.RENDER_FILE, nextFile);

      const requestIdle = () =>
        requestIdleCallback((idleDeadline) => {
          // Wait for at least 5ms before trying to render
          // or for 5 tries and then force render the file
          if (idleDeadline.timeRemaining() >= 5 || retryCount > 4) {
            checkItem();
          } else {
            requestIdle();
            retryCount += 1;
          }
        });

      requestIdle();
    }
  };

  if (diffFilesToRender.length) {
    checkItem();
  }
};

export const setRenderIt = ({ commit }, file) => commit(types.RENDER_FILE, file);

export const setInlineDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE);

  Cookies.set(DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: INLINE_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);

  if (window.gon?.features?.diffSettingsUsageData) {
    api.trackRedisHllUserEvent(TRACKING_CLICK_DIFF_VIEW_SETTING);
    api.trackRedisHllUserEvent(TRACKING_DIFF_VIEW_INLINE);
  }
};

export const setParallelDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE);

  Cookies.set(DIFF_VIEW_COOKIE_NAME, PARALLEL_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: PARALLEL_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);

  if (window.gon?.features?.diffSettingsUsageData) {
    api.trackRedisHllUserEvent(TRACKING_CLICK_DIFF_VIEW_SETTING);
    api.trackRedisHllUserEvent(TRACKING_DIFF_VIEW_PARALLEL);
  }
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

  return axios.get(endpoint, { params }).then((res) => {
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
    .then((res) => {
      commit(types.ADD_COLLAPSED_DIFFS, {
        file,
        data: res.data,
      });
    });

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

  discussions.forEach((discussion) => {
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
  const lineCodesWithDiscussions = new Set();
  const lineHasDiscussion = (line) => Boolean(line?.discussions.length);
  const registerDiscussionLine = (line) => lineCodesWithDiscussions.add(line.line_code);

  diff[INLINE_DIFF_LINES_KEY].filter(lineHasDiscussion).forEach(registerDiscussionLine);

  if (lineCodesWithDiscussions.size) {
    Array.from(lineCodesWithDiscussions).forEach((lineCode) => {
      commit(types.TOGGLE_LINE_DISCUSSIONS, {
        fileHash: diff.file_hash,
        expanded: !discussionWrappersExpanded,
        lineCode,
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
    .then((result) => dispatch('updateDiscussion', result.discussion, { root: true }))
    .then((discussion) => dispatch('assignDiscussionsToDiff', [discussion]))
    .then(() => dispatch('updateResolvableDiscussionsCounts', null, { root: true }))
    .then(() => dispatch('closeDiffFileCommentForm', formData.diffFile.file_hash))
    .catch(() =>
      createFlash({
        message: s__('MergeRequests|Saving the comment failed'),
      }),
    );
};

export const toggleTreeOpen = ({ commit }, path) => {
  commit(types.TOGGLE_FOLDER_OPEN, path);
};

export const toggleActiveFileByHash = ({ commit }, hash) => {
  commit(types.VIEW_DIFF_FILE, hash);
};

export const scrollToFile = ({ state, commit }, path) => {
  if (!state.treeEntries[path]) return;

  const { fileHash } = state.treeEntries[path];

  commit(types.VIEW_DIFF_FILE, fileHash);

  if (window.gon?.features?.diffsVirtualScrolling) {
    eventHub.$emit('scrollToFileHash', fileHash);

    setTimeout(() => {
      window.history.replaceState(null, null, `#${fileHash}`);
    });
  } else {
    document.location.hash = fileHash;
  }
};

export const setShowTreeList = ({ commit }, { showTreeList, saving = true }) => {
  commit(types.SET_SHOW_TREE_LIST, showTreeList);

  if (saving) {
    localStorage.setItem(MR_TREE_SHOW_KEY, showTreeList);
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

  if (window.gon?.features?.diffSettingsUsageData) {
    api.trackRedisHllUserEvent(TRACKING_CLICK_FILE_BROWSER_SETTING);

    if (renderTreeList) {
      api.trackRedisHllUserEvent(TRACKING_FILE_BROWSER_TREE);
    } else {
      api.trackRedisHllUserEvent(TRACKING_FILE_BROWSER_LIST);
    }
  }
};

export const setShowWhitespace = async (
  { state, commit },
  { url, showWhitespace, updateDatabase = true },
) => {
  if (updateDatabase && Boolean(window.gon?.current_user_id)) {
    await axios.put(url || state.endpointUpdateUser, { show_whitespace_in_diffs: showWhitespace });
  }

  commit(types.SET_SHOW_WHITESPACE, showWhitespace);
  notesEventHub.$emit('refetchDiffData');

  if (window.gon?.features?.diffSettingsUsageData) {
    api.trackRedisHllUserEvent(TRACKING_CLICK_WHITESPACE_SETTING);

    if (showWhitespace) {
      api.trackRedisHllUserEvent(TRACKING_WHITESPACE_SHOW);
    } else {
      api.trackRedisHllUserEvent(TRACKING_WHITESPACE_HIDE);
    }
  }
};

export const toggleFileFinder = ({ commit }, visible) => {
  commit(types.TOGGLE_FILE_FINDER_VISIBLE, visible);
};

export const cacheTreeListWidth = (_, size) => {
  localStorage.setItem(TREE_LIST_WIDTH_STORAGE_KEY, size);
};

export const receiveFullDiffError = ({ commit }, filePath) => {
  commit(types.RECEIVE_FULL_DIFF_ERROR, filePath);
  createFlash({
    message: s__('MergeRequest|Error loading full diff. Please try again.'),
  });
};

export const setExpandedDiffLines = ({ commit }, { file, data }) => {
  const expandedDiffLines = convertExpandLines({
    diffLines: file[INLINE_DIFF_LINES_KEY],
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
  });

  if (expandedDiffLines.length > MAX_RENDERING_DIFF_LINES) {
    let index = START_RENDERING_INDEX;
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines.slice(0, index),
    });
    commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);

    const idleCb = (t) => {
      const startIndex = index;

      while (
        t.timeRemaining() >= MIN_RENDERING_MS &&
        index !== expandedDiffLines.length &&
        index - startIndex !== MAX_RENDERING_BULK_ROWS
      ) {
        const line = expandedDiffLines[index];

        if (line) {
          commit(types.ADD_CURRENT_VIEW_DIFF_FILE_LINES, { filePath: file.file_path, line });
          index += 1;
        }
      }

      if (index !== expandedDiffLines.length) {
        idleCallback(idleCb);
      } else {
        commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);
      }
    };

    idleCallback(idleCb);
  } else {
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines,
    });
  }
};

export const fetchFullDiff = ({ commit, dispatch }, file) =>
  axios
    .get(file.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      commit(types.RECEIVE_FULL_DIFF_SUCCESS, { filePath: file.file_path });

      dispatch('setExpandedDiffLines', { file, data });
    })
    .catch(() => dispatch('receiveFullDiffError', file.file_path));

export const toggleFullDiff = ({ dispatch, commit, getters, state }, filePath) => {
  const file = state.diffFiles.find((f) => f.file_path === filePath);

  commit(types.REQUEST_FULL_DIFF, filePath);

  if (file.isShowingFullFile) {
    dispatch('loadCollapsedDiff', file)
      .then(() => dispatch('assignDiscussionsToDiff', getters.getDiffFileDiscussions(file)))
      .catch(() => dispatch('receiveFullDiffError', filePath));
  } else {
    dispatch('fetchFullDiff', file);
  }
};

export function switchToFullDiffFromRenamedFile({ commit, dispatch }, { diffFile }) {
  return axios
    .get(diffFile.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      const lines = data.map((line, index) =>
        prepareLineForRenamedFile({
          diffViewType: 'inline',
          line,
          diffFile,
          index,
        }),
      );

      commit(types.SET_DIFF_FILE_VIEWER, {
        filePath: diffFile.file_path,
        viewer: {
          ...diffFile.alternate_viewer,
          automaticallyCollapsed: false,
          manuallyCollapsed: false,
        },
      });
      commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, { filePath: diffFile.file_path, lines });

      dispatch('startRenderDiffsQueue');
    });
}

export const setFileCollapsedByUser = ({ commit }, { filePath, collapsed }) => {
  commit(types.SET_FILE_COLLAPSED, { filePath, collapsed, trigger: DIFF_FILE_MANUAL_COLLAPSE });
};

export const setSuggestPopoverDismissed = ({ commit, state }) =>
  axios
    .post(state.dismissEndpoint, {
      feature_name: 'suggest_popover_dismissed',
    })
    .then(() => {
      commit(types.SET_SHOW_SUGGEST_POPOVER);
    })
    .catch(() => {
      createFlash({
        message: s__('MergeRequest|Error dismissing suggestion popover. Please try again.'),
      });
    });

export function changeCurrentCommit({ dispatch, commit, state }, { commitId }) {
  /* eslint-disable @gitlab/require-i18n-strings */
  if (!commitId) {
    return Promise.reject(new Error('`commitId` is a required argument'));
  } else if (!state.commit) {
    return Promise.reject(new Error('`state` must already contain a valid `commit`'));
  }
  /* eslint-enable @gitlab/require-i18n-strings */

  // this is less than ideal, see: https://gitlab.com/gitlab-org/gitlab/-/issues/215421
  const commitRE = new RegExp(state.commit.id, 'g');

  commit(types.SET_DIFF_FILES, []);
  commit(types.SET_BASE_CONFIG, {
    ...state,
    endpoint: state.endpoint.replace(commitRE, commitId),
    endpointBatch: state.endpointBatch.replace(commitRE, commitId),
    endpointMetadata: state.endpointMetadata.replace(commitRE, commitId),
  });

  return dispatch('fetchDiffFilesMeta');
}

export function moveToNeighboringCommit({ dispatch, state }, { direction }) {
  const previousCommitId = state.commit?.prev_commit_id;
  const nextCommitId = state.commit?.next_commit_id;
  const canMove = {
    next: !state.isLoading && nextCommitId,
    previous: !state.isLoading && previousCommitId,
  };
  let commitId;

  if (direction === 'next' && canMove.next) {
    commitId = nextCommitId;
  } else if (direction === 'previous' && canMove.previous) {
    commitId = previousCommitId;
  }

  if (commitId) {
    dispatch('changeCurrentCommit', { commitId });
  }
}

export const setCurrentDiffFileIdFromNote = ({ commit, state, rootGetters }, noteId) => {
  const note = rootGetters.notesById[noteId];

  if (!note) return;

  const fileHash = rootGetters.getDiscussion(note.discussion_id).diff_file?.file_hash;

  if (fileHash && state.diffFiles.some((f) => f.file_hash === fileHash)) {
    commit(types.VIEW_DIFF_FILE, fileHash);
  }
};

export const navigateToDiffFileIndex = ({ commit, state }, index) => {
  const fileHash = state.diffFiles[index].file_hash;
  document.location.hash = fileHash;

  commit(types.VIEW_DIFF_FILE, fileHash);
};

export const setFileByFile = ({ state, commit }, { fileByFile }) => {
  const fileViewMode = fileByFile ? DIFF_VIEW_FILE_BY_FILE : DIFF_VIEW_ALL_FILES;
  commit(types.SET_FILE_BY_FILE, fileByFile);
  Cookies.set(DIFF_FILE_BY_FILE_COOKIE_NAME, fileViewMode);

  if (window.gon?.features?.diffSettingsUsageData) {
    api.trackRedisHllUserEvent(TRACKING_CLICK_SINGLE_FILE_SETTING);

    if (fileByFile) {
      api.trackRedisHllUserEvent(TRACKING_SINGLE_FILE_MODE);
    } else {
      api.trackRedisHllUserEvent(TRACKING_MULTIPLE_FILES_MODE);
    }
  }

  return axios
    .put(state.endpointUpdateUser, {
      view_diffs_file_by_file: fileByFile,
    })
    .then(() => {
      // https://gitlab.com/gitlab-org/gitlab/-/issues/326961
      // We can't even do a simple console warning here because
      // the pipeline will fail. However, the issue above will
      // eventually handle errors appropriately.
      // console.warn('Saving the file-by-fil user preference failed.');
    });
};

export function reviewFile({ commit, state }, { file, reviewed = true }) {
  const { mrPath } = getDerivedMergeRequestInformation({ endpoint: file.load_collapsed_diff_url });
  const reviews = markFileReview(state.mrReviews, file, reviewed);

  setReviewsForMergeRequest(mrPath, reviews);
  commit(types.SET_MR_FILE_REVIEWS, reviews);
}
