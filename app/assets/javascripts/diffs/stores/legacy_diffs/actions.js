import Vue from 'vue';
import {
  setCookie,
  handleLocationHash,
  historyPushState,
  scrollToElement,
} from '~/lib/utils/common_utils';
import { createAlert, VARIANT_WARNING } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import {
  mergeUrlParams,
  getLocationHash,
  getParameterValues,
  removeParams,
} from '~/lib/utils/url_utility';
import notesEventHub from '~/notes/event_hub';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { sortTree } from '~/ide/stores/utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import {
  countLinesInBetween,
  findClosestMatchLine,
  isCollapsed,
  lineExists,
} from '~/diffs/utils/diff_file';
import { useNotes } from '~/notes/store/legacy_notes';
import {
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  MR_TREE_SHOW_KEY,
  TREE_LIST_STORAGE_KEY,
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
  EVT_MR_PREPARED,
  FILE_DIFF_POSITION_TYPE,
  EVT_DISCUSSIONS_ASSIGNED,
} from '../../constants';
import {
  DISCUSSION_SINGLE_DIFF_FAILED,
  BUILDING_YOUR_MR,
  SOMETHING_WENT_WRONG,
  ERROR_LOADING_FULL_DIFF,
  ERROR_DISMISSING_SUGESTION_POPOVER,
  ENCODED_FILE_PATHS_TITLE,
  ENCODED_FILE_PATHS_MESSAGE,
} from '../../i18n';
import eventHub from '../../event_hub';
import { markFileReview, setReviewsForMergeRequest } from '../../utils/file_reviews';
import { getDerivedMergeRequestInformation } from '../../utils/merge_request';
import { queueRedisHllEvents } from '../../utils/queue_events';
import * as types from '../../store/mutation_types';
import {
  getDiffPositionByLineCode,
  getNoteFormData,
  convertExpandLines,
  idleCallback,
  prepareLineForRenamedFile,
  parseUrlHashAsFileHash,
  isUrlHashNoteLink,
  findDiffFile,
} from '../../store/utils';

export function setBaseConfig(options) {
  const {
    endpoint,
    endpointMetadata,
    endpointBatch,
    endpointDiffForPath,
    endpointCoverage,
    endpointUpdateUser,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
    defaultSuggestionCommitMessage,
    viewDiffsFileByFile,
    mrReviews,
    diffViewType,
    perPage,
  } = options;
  this[types.SET_BASE_CONFIG]({
    endpoint,
    endpointMetadata,
    endpointBatch,
    endpointDiffForPath,
    endpointCoverage,
    endpointUpdateUser,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
    defaultSuggestionCommitMessage,
    viewDiffsFileByFile,
    mrReviews,
    diffViewType,
    perPage,
  });

  Array.from(new Set(Object.values(mrReviews).flat())).forEach((id) => {
    const viewedId = id.replace(/^hash:/, '');

    this[types.SET_DIFF_FILE_VIEWED]({ id: viewedId, seen: true });
  });
}

export async function prefetchSingleFile(treeEntry) {
  const url = new URL(this.endpointBatch, 'https://gitlab.com');
  const diffId = getParameterValues('diff_id', url)[0];
  const startSha = getParameterValues('start_sha', url)[0];

  if (
    treeEntry &&
    !treeEntry.diffLoaded &&
    !treeEntry.diffLoading &&
    !this.getDiffFileByHash(treeEntry.fileHash)
  ) {
    const urlParams = {
      old_path: treeEntry.filePaths.old,
      new_path: treeEntry.filePaths.new,
      w: this.showWhitespace ? '0' : '1',
      view: 'inline',
      commit_id: this.commitId,
      diff_head: true,
    };

    if (diffId) {
      urlParams.diff_id = diffId;
    }

    if (startSha) {
      urlParams.start_sha = startSha;
    }

    this[types.TREE_ENTRY_DIFF_LOADING]({ path: treeEntry.filePaths.new });

    try {
      const { data: diffData } = await axios.get(
        mergeUrlParams({ ...urlParams }, this.endpointDiffForPath),
      );

      this[types.SET_DIFF_DATA_BATCH]({ diff_files: diffData.diff_files });

      eventHub.$emit('diffFilesModified');
    } catch (e) {
      this[types.TREE_ENTRY_DIFF_LOADING]({ path: treeEntry.filePaths.new, loading: false });
    }
  }
}

export async function fetchFileByFile() {
  const isNoteLink = isUrlHashNoteLink(window?.location?.hash);
  const id = parseUrlHashAsFileHash(window?.location?.hash, this.currentDiffFileId);
  const url = new URL(this.endpointBatch, 'https://gitlab.com');
  const diffId = getParameterValues('diff_id', url)[0];
  const startSha = getParameterValues('start_sha', url)[0];
  const treeEntry = id
    ? this.flatBlobsList.find(({ fileHash }) => fileHash === id)
    : this.flatBlobsList[0];

  eventHub.$emit(EVT_PERF_MARK_DIFF_FILES_START);

  if (treeEntry && !treeEntry.diffLoaded && !this.getDiffFileByHash(id)) {
    // Overloading "batch" loading indicators so the UI stays mostly the same
    this[types.SET_BATCH_LOADING_STATE]('loading');
    this[types.SET_RETRIEVING_BATCHES](true);

    const urlParams = {
      old_path: treeEntry.filePaths.old,
      new_path: treeEntry.filePaths.new,
      w: this.showWhitespace ? '0' : '1',
      view: 'inline',
      commit_id: this.commitId,
      diff_head: true,
    };

    if (diffId) {
      urlParams.diff_id = diffId;
    }

    if (startSha) {
      urlParams.start_sha = startSha;
    }

    axios
      .get(mergeUrlParams({ ...urlParams }, this.endpointDiffForPath))
      .then(({ data: diffData }) => {
        this[types.SET_DIFF_DATA_BATCH]({ diff_files: diffData.diff_files });

        if (!isNoteLink && !this.currentDiffFileId) {
          this[types.SET_CURRENT_DIFF_FILE](this.diffFiles[0]?.file_hash || '');
        }

        this[types.SET_BATCH_LOADING_STATE]('loaded');

        eventHub.$emit('diffFilesModified');
      })
      .catch(() => {
        this[types.SET_BATCH_LOADING_STATE]('error');
      })
      .finally(() => {
        this[types.SET_RETRIEVING_BATCHES](false);
      });
  }
}

export function fetchDiffFilesBatch(linkedFileLoading = false) {
  let perPage = this.viewDiffsFileByFile ? 1 : this.perPage;
  let increaseAmount = 1.4;
  const startPage = 0;
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const urlParams = {
    w: this.showWhitespace ? '0' : '1',
    view: 'inline',
  };
  const hash = window.location.hash.replace('#', '').split('diff-content-').pop();
  let totalLoaded = 0;
  let scrolledVirtualScroller = hash === '';

  if (!linkedFileLoading) {
    this[types.SET_BATCH_LOADING_STATE]('loading');
    this[types.SET_RETRIEVING_BATCHES](true);
  }
  eventHub.$emit(EVT_PERF_MARK_DIFF_FILES_START);

  const getBatch = (page = startPage) =>
    axios
      .get(mergeUrlParams({ ...urlParams, page, per_page: perPage }, this.endpointBatch))
      .then(({ data: { pagination, diff_files: diffFiles } }) => {
        totalLoaded += diffFiles.length;

        this[types.SET_DIFF_DATA_BATCH]({ diff_files: diffFiles });
        this[types.SET_BATCH_LOADING_STATE]('loaded');

        if (!scrolledVirtualScroller && !linkedFileLoading) {
          const index = this.diffFiles.findIndex(
            (f) =>
              f.file_hash === hash || f[INLINE_DIFF_LINES_KEY].find((l) => l.line_code === hash),
          );

          if (index >= 0) {
            eventHub.$emit('scrollToIndex', index);
            scrolledVirtualScroller = true;
          }
        }

        if (!isNoteLink && !this.currentDiffFileId) {
          this[types.SET_CURRENT_DIFF_FILE](diffFiles[0]?.file_hash);
        }

        if (isNoteLink) {
          this.setCurrentDiffFileIdFromNote(id.split('_').pop());
        }

        if (totalLoaded === pagination.total_pages || pagination.total_pages === null) {
          this[types.SET_RETRIEVING_BATCHES](false);
          eventHub.$emit('doneLoadingBatches');

          // We need to check that the currentDiffFileId points to a file that exists
          if (
            this.currentDiffFileId &&
            !this.diffFiles.some((f) => f.file_hash === this.currentDiffFileId) &&
            !isNoteLink
          ) {
            this[types.SET_CURRENT_DIFF_FILE](this.diffFiles[0].file_hash);
          }

          if (this.diffFiles?.length) {
            // eslint-disable-next-line promise/catch-or-return,promise/no-nesting
            import('~/code_navigation').then((m) =>
              m.default({
                blobs: this.diffFiles
                  .filter((f) => f.code_navigation_path)
                  .map((f) => ({
                    path: f.new_path,
                    codeNavigationPath: f.code_navigation_path,
                  })),
                definitionPathPrefix: this.definitionPathPrefix,
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
        if (nextPage) {
          return getBatch(nextPage);
        }

        return null;
      })
      .catch((error) => {
        this[types.SET_RETRIEVING_BATCHES](false);
        this[types.SET_BATCH_LOADING_STATE]('error');
        throw error;
      });

  return getBatch();
}

export function fetchDiffFilesMeta() {
  const urlParams = {
    view: 'inline',
    w: this.showWhitespace ? '0' : '1',
  };

  this[types.SET_LOADING](true);

  return axios
    .get(mergeUrlParams(urlParams, this.endpointMetadata))
    .then(({ data }) => {
      const strippedData = { ...data };
      delete strippedData.diff_files;

      if (strippedData.has_encoded_file_paths) {
        createAlert({
          title: ENCODED_FILE_PATHS_TITLE,
          message: ENCODED_FILE_PATHS_MESSAGE,
          dismissible: false,
        });
      }

      this[types.SET_LOADING](false);
      this[types.SET_MERGE_REQUEST_DIFFS](data.merge_request_diffs || []);
      this[types.SET_DIFF_METADATA](strippedData);

      eventHub.$emit(EVT_PERF_MARK_FILE_TREE_START);
      const { treeEntries, tree } = generateTreeList(data.diff_files);
      eventHub.$emit(EVT_PERF_MARK_FILE_TREE_END);
      this[types.SET_TREE_DATA]({
        treeEntries,
        tree: sortTree(tree),
      });

      return data;
    })
    .catch((error) => {
      if (error.response.status === HTTP_STATUS_NOT_FOUND) {
        const alert = createAlert({
          message: BUILDING_YOUR_MR,
          variant: VARIANT_WARNING,
        });

        eventHub.$once(EVT_MR_PREPARED, () => alert.dismiss());
      } else {
        throw error;
      }
    });
}

export function prefetchFileNeighbors() {
  const { flatBlobsList: allBlobs, currentDiffIndex: currentIndex } = this;

  const previous = Math.max(currentIndex - 1, 0);
  const next = Math.min(allBlobs.length - 1, currentIndex + 1);

  this.prefetchSingleFile(allBlobs[next]);
  this.prefetchSingleFile(allBlobs[previous]);
}

export function fetchCoverageFiles() {
  const coveragePoll = new Poll({
    resource: {
      getCoverageReports: (endpoint) => axios.get(endpoint),
    },
    data: this.endpointCoverage,
    method: 'getCoverageReports',
    successCallback: ({ status, data }) => {
      if (status === HTTP_STATUS_OK) {
        this[types.SET_COVERAGE_DATA](data);

        coveragePoll.stop();
      }
    },
    errorCallback: () =>
      createAlert({
        message: SOMETHING_WENT_WRONG,
      }),
  });

  coveragePoll.makeRequest();
}

export function setHighlightedRow({ lineCode, event }) {
  if (event && event.target.href) {
    event.preventDefault();
    window.history.replaceState(null, undefined, removeParams(['file'], event.target.href));
  }
  const fileHash = lineCode.split('_')[0];
  this[types.SET_HIGHLIGHTED_ROW](lineCode);
  this[types.SET_CURRENT_DIFF_FILE](fileHash);

  handleLocationHash();
}

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export function assignDiscussionsToDiff(discussions) {
  const targetDiscussions = discussions || useNotes().discussions;
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const diffPositionByLineCode = getDiffPositionByLineCode(this.diffFiles);
  const hash = getLocationHash();

  targetDiscussions
    .filter((discussion) => discussion?.diff_discussion)
    .forEach((discussion) => {
      this[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
        hash,
      });
    });

  if (isNoteLink) {
    this.setCurrentDiffFileIdFromNote(id.split('_').pop());
  }

  Vue.nextTick(() => {
    eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
  });
}

export function removeDiscussionsFromDiff(removeDiscussion) {
  if (!removeDiscussion.diff_file) return;

  const {
    diff_file: { file_hash: fileHash },
    line_code: lineCode,
    id,
  } = removeDiscussion;
  this[types.REMOVE_LINE_DISCUSSIONS_FOR_FILE]({ fileHash, lineCode, id });
}

export function toggleLineDiscussions(options) {
  this[types.TOGGLE_LINE_DISCUSSIONS](options);
}

export function renderFileForDiscussionId(discussionId) {
  const discussion = useNotes().discussions.find((d) => d.id === discussionId);

  if (discussion && discussion.diff_file) {
    const file = this.diffFiles.find((f) => f.file_hash === discussion.diff_file.file_hash);

    if (file) {
      if (file.viewer.automaticallyCollapsed) {
        notesEventHub.$emit(`loadCollapsedDiff/${file.file_hash}`);
        scrollToElement(document.getElementById(file.file_hash));
      } else if (file.viewer.manuallyCollapsed) {
        this[types.SET_FILE_COLLAPSED]({
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
}

export function setDiffViewType(diffViewType) {
  this[types.SET_DIFF_VIEW_TYPE](diffViewType);

  setCookie(DIFF_VIEW_COOKIE_NAME, diffViewType);
  const url = mergeUrlParams({ view: diffViewType }, window.location.href);
  historyPushState(url);

  queueRedisHllEvents([
    TRACKING_CLICK_DIFF_VIEW_SETTING,
    diffViewType === INLINE_DIFF_VIEW_TYPE
      ? TRACKING_DIFF_VIEW_INLINE
      : TRACKING_DIFF_VIEW_PARALLEL,
  ]);
}

export function showCommentForm({ lineCode, fileHash }) {
  this[types.TOGGLE_LINE_HAS_FORM]({ lineCode, fileHash, hasForm: true });

  // The comment form for diffs gets focussed differently due to the way the virtual scroller
  // works. If we focus the comment form on mount and the comment form gets removed and then
  // added again the page will scroll in unexpected ways
  setTimeout(() => {
    const el = document.querySelector(
      `[data-line-code="${lineCode}"] textarea, [data-line-code="${lineCode}"] [contenteditable="true"]`,
    );

    if (!el) return;

    const { bottom } = el.getBoundingClientRect();
    const overflowBottom = bottom - window.innerHeight;

    // Prevent the browser scrolling for us
    // We handle the scrolling to not break the diffs virtual scroller
    el.focus({ preventScroll: true });

    if (overflowBottom > 0) {
      window.scrollBy(0, Math.floor(Math.abs(overflowBottom)) + 150);
    }
  });
}

export function cancelCommentForm({ lineCode, fileHash }) {
  this[types.TOGGLE_LINE_HAS_FORM]({ lineCode, fileHash, hasForm: false });
}

export function loadMoreLines(options) {
  const { endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers } = options;

  params.from_merge_request = true;

  return axios.get(endpoint, { params }).then((res) => {
    const contextLines = res.data || [];

    this[types.ADD_CONTEXT_LINES]({
      lineNumbers,
      contextLines,
      params,
      fileHash,
      isExpandDown,
      nextLineNumbers,
    });
  });
}

export function scrollToLineIfNeededInline(line) {
  const hash = getLocationHash();

  if (hash && line.line_code === hash) {
    handleLocationHash();
  }
}

export function scrollToLineIfNeededParallel(line) {
  const hash = getLocationHash();

  if (
    hash &&
    ((line.left && line.left.line_code === hash) || (line.right && line.right.line_code === hash))
  ) {
    handleLocationHash();
  }
}

export function loadCollapsedDiff({ file, params = {} }) {
  const versionPath = this.mergeRequestDiff?.version_path;
  const loadParams = {
    commit_id: this.commitId,
    w: this.showWhitespace ? '0' : '1',
    ...params,
  };

  if (versionPath) {
    const { diffId, startSha } = getDerivedMergeRequestInformation({ endpoint: versionPath });

    loadParams.diff_id = diffId;
    loadParams.start_sha = startSha;
  }

  return axios.get(file.load_collapsed_diff_url, { params: loadParams }).then((res) => {
    this[types.ADD_COLLAPSED_DIFFS]({
      file,
      data: res.data,
    });
  });
}

/**
 * Toggles the file discussions after user clicked on the toggle discussions button.
 * @param {Object} discussion
 */
export function toggleFileDiscussion(discussion) {
  this[types.TOGGLE_FILE_DISCUSSION_EXPAND]({ discussion });
}

export function toggleFileDiscussionWrappers(diff) {
  const discussionWrappersExpanded = this.diffHasExpandedDiscussions(diff);
  const lineCodesWithDiscussions = new Set();
  const lineHasDiscussion = (line) => Boolean(line?.discussions.length);
  const registerDiscussionLine = (line) => lineCodesWithDiscussions.add(line.line_code);

  diff[INLINE_DIFF_LINES_KEY].filter(lineHasDiscussion).forEach(registerDiscussionLine);

  if (lineCodesWithDiscussions.size) {
    Array.from(lineCodesWithDiscussions).forEach((lineCode) => {
      this[types.TOGGLE_LINE_DISCUSSIONS]({
        fileHash: diff.file_hash,
        expanded: !discussionWrappersExpanded,
        lineCode,
      });
    });
  }

  if (diff.discussions.length) {
    diff.discussions.forEach((discussion) => {
      if (discussion.position?.position_type === FILE_DIFF_POSITION_TYPE) {
        this[types.TOGGLE_FILE_DISCUSSION_EXPAND]({
          discussion,
          expandedOnDiff: !discussionWrappersExpanded,
        });
      }
    });
  }
}

export async function saveDiffDiscussion({ note, formData }) {
  const postData = getNoteFormData({
    commit: this.commit,
    note,
    showWhitespace: this.showWhitespace,
    ...formData,
  });

  const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: note });
  if (!confirmSubmit) {
    return null;
  }

  return useNotes()
    .saveNote(postData)
    .then((result) => useNotes().updateDiscussion(result.discussion))
    .then((discussion) => this.assignDiscussionsToDiff([discussion]))
    .then(() => useNotes().updateResolvableDiscussionsCounts(null))
    .then(() => this.closeDiffFileCommentForm(formData.diffFile.file_hash))
    .then(() => {
      if (formData.positionType === FILE_DIFF_POSITION_TYPE) {
        this.toggleFileCommentForm(formData.diffFile.file_path);
      }
    });
}

export function toggleTreeOpen(path) {
  this[types.TOGGLE_FOLDER_OPEN](path);
}

export function setTreeOpen({ path, opened }) {
  this[types.SET_FOLDER_OPEN]({ path, opened });
}

export function setCurrentFileHash(hash) {
  this[types.SET_CURRENT_DIFF_FILE](hash);
}

export function goToFile({ path }) {
  if (!this.viewDiffsFileByFile) {
    this.scrollToFile({ path });
  } else {
    if (!this.treeEntries[path]) return;

    this.unlinkFile();

    const { fileHash } = this.treeEntries[path];

    this[types.SET_CURRENT_DIFF_FILE](fileHash);

    const newUrl = new URL(window.location);
    newUrl.hash = fileHash;
    historyPushState(newUrl, { skipScrolling: true });
    scrollToElement('.diff-files-holder', { duration: 0 });

    if (!this.isTreePathLoaded(path)) {
      this.fetchFileByFile();
    }
  }
}

export function scrollToFile({ path }) {
  if (!this.treeEntries[path]) return;

  const { fileHash } = this.treeEntries[path];

  this[types.SET_CURRENT_DIFF_FILE](fileHash);

  if (this.isVirtualScrollingEnabled) {
    eventHub.$emit('scrollToFileHash', fileHash);

    setTimeout(() => {
      window.history.replaceState(null, null, `#${fileHash}`);
    });
  } else {
    document.location.hash = fileHash;

    setTimeout(() => {
      handleLocationHash();
    });
  }
}

export function setShowTreeList({ showTreeList, saving = true }) {
  this[types.SET_SHOW_TREE_LIST](showTreeList);

  if (saving) {
    localStorage.setItem(MR_TREE_SHOW_KEY, showTreeList);
  }
}

export function toggleTreeList() {
  this[types.SET_SHOW_TREE_LIST](!this.showTreeList);
}

export function openDiffFileCommentForm(formData) {
  const form = this.getCommentFormForDiffFile(formData.fileHash);

  if (form) {
    this[types.UPDATE_DIFF_FILE_COMMENT_FORM](formData);
  } else {
    this[types.OPEN_DIFF_FILE_COMMENT_FORM](formData);
  }
}

export function closeDiffFileCommentForm(fileHash) {
  this[types.CLOSE_DIFF_FILE_COMMENT_FORM](fileHash);
}

export function setRenderTreeList({ renderTreeList, trackClick = true }) {
  this[types.SET_RENDER_TREE_LIST](renderTreeList);

  localStorage.setItem(TREE_LIST_STORAGE_KEY, renderTreeList);

  if (trackClick) {
    const events = [TRACKING_CLICK_FILE_BROWSER_SETTING];

    if (renderTreeList) {
      events.push(TRACKING_FILE_BROWSER_TREE);
    } else {
      events.push(TRACKING_FILE_BROWSER_LIST);
    }

    queueRedisHllEvents(events);
  }
}

export async function setShowWhitespace({
  url,
  showWhitespace,
  updateDatabase = true,
  trackClick = true,
}) {
  if (updateDatabase && Boolean(window.gon?.current_user_id)) {
    await axios.put(url || this.endpointUpdateUser, { show_whitespace_in_diffs: showWhitespace });
  }

  this[types.SET_SHOW_WHITESPACE](showWhitespace);
  notesEventHub.$emit('refetchDiffData');

  if (trackClick) {
    const events = [TRACKING_CLICK_WHITESPACE_SETTING];

    if (showWhitespace) {
      events.push(TRACKING_WHITESPACE_SHOW);
    } else {
      events.push(TRACKING_WHITESPACE_HIDE);
    }

    queueRedisHllEvents(events);
  }
}

export function toggleFileFinder(visible) {
  this[types.TOGGLE_FILE_FINDER_VISIBLE](visible);
}

export function receiveFullDiffError(filePath) {
  this[types.RECEIVE_FULL_DIFF_ERROR](filePath);
  createAlert({
    message: ERROR_LOADING_FULL_DIFF,
  });
}

export function setExpandedDiffLines({ file, data }) {
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
    this[types.SET_CURRENT_VIEW_DIFF_FILE_LINES]({
      filePath: file.file_path,
      lines: expandedDiffLines.slice(0, index),
    });
    this[types.TOGGLE_DIFF_FILE_RENDERING_MORE](file.file_path);

    const idleCb = (t) => {
      const startIndex = index;

      while (
        t.timeRemaining() >= MIN_RENDERING_MS &&
        index !== expandedDiffLines.length &&
        index - startIndex !== MAX_RENDERING_BULK_ROWS
      ) {
        const line = expandedDiffLines[index];

        if (line) {
          this[types.ADD_CURRENT_VIEW_DIFF_FILE_LINES]({ filePath: file.file_path, line });
          index += 1;
        }
      }

      if (index !== expandedDiffLines.length) {
        idleCallback(idleCb);
      } else {
        this[types.TOGGLE_DIFF_FILE_RENDERING_MORE](file.file_path);
      }
    };

    idleCallback(idleCb);
  } else {
    this[types.SET_CURRENT_VIEW_DIFF_FILE_LINES]({
      filePath: file.file_path,
      lines: expandedDiffLines,
    });
  }
}

export function fetchFullDiff(file) {
  return axios
    .get(file.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      this[types.RECEIVE_FULL_DIFF_SUCCESS]({ filePath: file.file_path });

      this.setExpandedDiffLines({ file, data });
    })
    .catch(() => this.receiveFullDiffError(file.file_path));
}

export function toggleFullDiff(filePath) {
  const file = this.diffFiles.find((f) => f.file_path === filePath);

  this[types.REQUEST_FULL_DIFF](filePath);

  if (file.isShowingFullFile) {
    this.loadCollapsedDiff({ file })
      .then(() => this.assignDiscussionsToDiff(this.getDiffFileDiscussions(file)))
      .catch(() => this.receiveFullDiffError(filePath));
  } else {
    this.fetchFullDiff(file);
  }
}

export function switchToFullDiffFromRenamedFile({ diffFile }) {
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

      this[types.SET_DIFF_FILE_VIEWER]({
        filePath: diffFile.file_path,
        viewer: {
          ...diffFile.alternate_viewer,
          automaticallyCollapsed: false,
          manuallyCollapsed: false,
          forceOpen: false,
        },
      });
      this[types.SET_CURRENT_VIEW_DIFF_FILE_LINES]({ filePath: diffFile.file_path, lines });
    });
}

export function setFileCollapsedByUser({ filePath, collapsed }) {
  this[types.SET_FILE_COLLAPSED]({ filePath, collapsed, trigger: DIFF_FILE_MANUAL_COLLAPSE });
}

export function setFileCollapsedAutomatically({ filePath, collapsed }) {
  this[types.SET_FILE_COLLAPSED]({ filePath, collapsed, trigger: DIFF_FILE_AUTOMATIC_COLLAPSE });
}

export function setFileForcedOpen({ filePath, forced }) {
  this[types.SET_FILE_FORCED_OPEN]({ filePath, forced });
}

export function setSuggestPopoverDismissed() {
  return axios
    .post(this.dismissEndpoint, {
      feature_name: 'suggest_popover_dismissed',
    })
    .then(() => {
      this[types.SET_SHOW_SUGGEST_POPOVER]();
    })
    .catch(() => {
      createAlert({
        message: ERROR_DISMISSING_SUGESTION_POPOVER,
      });
    });
}

export function changeCurrentCommit({ commitId }) {
  if (!commitId) {
    return Promise.reject(new Error('`commitId` is a required argument'));
  }
  if (!this.commit) {
    return Promise.reject(new Error('`state` must already contain a valid `commit`')); // eslint-disable-line @gitlab/require-i18n-strings
  }

  // this is less than ideal, see: https://gitlab.com/gitlab-org/gitlab/-/issues/215421
  const commitRE = new RegExp(this.commit.id, 'g');

  this[types.SET_DIFF_FILES]([]);
  this[types.SET_BASE_CONFIG]({
    ...this.$state,
    endpoint: this.endpoint.replace(commitRE, commitId),
    endpointBatch: this.endpointBatch.replace(commitRE, commitId),
    endpointMetadata: this.endpointMetadata.replace(commitRE, commitId),
  });

  return this.fetchDiffFilesMeta();
}

export function moveToNeighboringCommit({ direction }) {
  const previousCommitId = this.commit?.prev_commit_id;
  const nextCommitId = this.commit?.next_commit_id;
  const canMove = {
    next: !this.isLoading && nextCommitId,
    previous: !this.isLoading && previousCommitId,
  };
  let commitId;

  if (direction === 'next' && canMove.next) {
    commitId = nextCommitId;
  } else if (direction === 'previous' && canMove.previous) {
    commitId = previousCommitId;
  }

  if (commitId) {
    this.changeCurrentCommit({ commitId });
  }
}

export function rereadNoteHash() {
  const urlHash = window?.location?.hash;

  if (isUrlHashNoteLink(urlHash)) {
    this.setCurrentDiffFileIdFromNote(urlHash.split('_').pop())
      .then(() => {
        if (this.viewDiffsFileByFile) {
          this.fetchFileByFile();
        }
      })
      .catch(() => {
        createAlert({
          message: DISCUSSION_SINGLE_DIFF_FAILED,
        });
      });
  }
}

export function setCurrentDiffFileIdFromNote(noteId) {
  const note = useNotes().notesById[noteId];

  if (!note) return;

  const fileHash = useNotes().getDiscussion(note.discussion_id).diff_file?.file_hash;

  if (fileHash && this.flatBlobsList.some((f) => f.fileHash === fileHash)) {
    this[types.SET_CURRENT_DIFF_FILE](fileHash);
  }
}

export function navigateToDiffFileIndex(index) {
  this.unlinkFile();

  const { fileHash } = this.flatBlobsList[index];
  document.location.hash = fileHash;

  this[types.SET_CURRENT_DIFF_FILE](fileHash);

  if (this.viewDiffsFileByFile) {
    this.fetchFileByFile();
  }
}

export function setFileByFile({ fileByFile }) {
  this[types.SET_FILE_BY_FILE](fileByFile);

  const events = [TRACKING_CLICK_SINGLE_FILE_SETTING];

  if (fileByFile) {
    events.push(TRACKING_SINGLE_FILE_MODE);
  } else {
    events.push(TRACKING_MULTIPLE_FILES_MODE);
  }

  queueRedisHllEvents(events);

  return axios
    .put(this.endpointUpdateUser, {
      view_diffs_file_by_file: fileByFile,
    })
    .then(() => {
      // https://gitlab.com/gitlab-org/gitlab/-/issues/326961
      // We can't even do a simple console warning here because
      // the pipeline will fail. However, the issue above will
      // eventually handle errors appropriately.
      // console.warn('Saving the file-by-fil user preference failed.');
    });
}

export function reviewFile({ file, reviewed = true }) {
  const { mrPath } = getDerivedMergeRequestInformation({ endpoint: file.load_collapsed_diff_url });
  const reviews = markFileReview(this.mrReviews, file, reviewed);

  setReviewsForMergeRequest(mrPath, reviews);

  this[types.SET_DIFF_FILE_VIEWED]({ id: file.id, seen: reviewed });
  this[types.SET_MR_FILE_REVIEWS](reviews);
}

export function disableVirtualScroller() {
  this[types.DISABLE_VIRTUAL_SCROLLING]();
}

export function toggleFileCommentForm(filePath) {
  const file = findDiffFile(this.diffFiles, filePath, 'file_path');
  if (isCollapsed(file)) {
    this[types.SET_FILE_COMMENT_FORM]({ filePath, expanded: true });
  } else {
    this[types.TOGGLE_FILE_COMMENT_FORM](filePath);
  }
  this[types.SET_FILE_COLLAPSED]({ filePath, collapsed: false });
}

export function addDraftToFile({ filePath, draft }) {
  return this[types.ADD_DRAFT_TO_FILE]({ filePath, draft });
}

export function fetchLinkedFile(linkedFileUrl) {
  const isNoteLink = isUrlHashNoteLink(window?.location?.hash);
  const [, fragmentFileHash, oldNumber, newNumber] =
    window.location.hash.substring(1).match(/^([0-9a-f]{40})_([0-9]+)_([0-9]+)$/) || [];

  this[types.SET_BATCH_LOADING_STATE]('loading');
  this[types.SET_RETRIEVING_BATCHES](true);

  return axios
    .get(linkedFileUrl)
    .then(async ({ data: diffData }) => {
      const [{ file_hash }] = diffData.diff_files;

      // we must store linked file in the `diffs`, otherwise collapsing and commenting on a file won't work
      // once the same file arrives in a file batch we must only update its' position
      // we also must not update file's position since it's loaded out of order
      this[types.SET_DIFF_DATA_BATCH]({ diff_files: diffData.diff_files, updatePosition: false });
      this[types.SET_LINKED_FILE_HASH](file_hash);

      if (!isNoteLink && !this.currentDiffFileId) {
        this[types.SET_CURRENT_DIFF_FILE](file_hash);
      }

      if (fragmentFileHash && oldNumber && newNumber) {
        await this.fetchLinkedExpandedLine({
          fileHash: fragmentFileHash,
          oldLine: parseInt(oldNumber, 10),
          newLine: parseInt(newNumber, 10),
        });
      }

      this[types.SET_BATCH_LOADING_STATE]('loaded');

      setTimeout(() => {
        handleLocationHash();
      });

      eventHub.$emit('diffFilesModified');
    })
    .catch((error) => {
      this[types.SET_BATCH_LOADING_STATE]('error');
      throw error;
    })
    .finally(() => {
      this[types.SET_RETRIEVING_BATCHES](false);
    });
}

export function fetchLinkedExpandedLine({ fileHash, oldLine, newLine }) {
  const file = this.linkedFile;
  if (!file || file.file_hash !== fileHash) return Promise.resolve();

  const lines = file[INLINE_DIFF_LINES_KEY];
  if (lineExists(lines, oldLine, newLine)) return Promise.resolve();

  const matchLine = findClosestMatchLine(lines, newLine);
  const { new_pos: matchNewPosition, old_pos: matchOldPosition } = matchLine.meta_data;
  const matchLineIndex = lines.indexOf(matchLine);
  const linesInBetween = countLinesInBetween(lines, matchLineIndex);
  const isExpandBoth = linesInBetween !== -1 && linesInBetween < 20;
  const previousLine = lines[matchLineIndex - 1];
  const previousLineNumber = previousLine?.new_line;
  const isLastMatchLine = matchLineIndex === lines.length - 1;
  const isExpandDown =
    isLastMatchLine ||
    (previousLine && !isExpandBoth && newLine - previousLineNumber < matchNewPosition - newLine);
  const loadLines = (params, rest) => {
    return this.loadMoreLines({
      endpoint: file.context_lines_path,
      fileHash: file.file_hash,
      params: {
        offset: matchNewPosition - matchOldPosition,
        ...params,
      },
      isExpandDown: false,
      lineNumbers: {
        oldLineNumber: matchOldPosition,
        newLineNumber: matchNewPosition,
      },
      ...rest,
    });
  };

  if (isExpandBoth) {
    return loadLines({
      unfold: false,
      since: previousLine.new_line + 1,
      to: matchNewPosition - 1,
      bottom: false,
    });
  }

  if (!isExpandDown) {
    return loadLines({
      unfold: true,
      since: newLine,
      to: matchNewPosition - 1,
      bottom: isLastMatchLine,
    });
  }

  const rest = {};
  if (!isLastMatchLine) {
    Object.assign(rest, {
      isExpandDown: true,
      lineNumbers: {
        oldLineNumber: previousLine.old_line,
        newLineNumber: previousLine.new_line,
      },
      nextLineNumbers: {
        old_line: matchOldPosition,
        new_line: matchNewPosition,
      },
    });
  }
  return loadLines(
    {
      unfold: true,
      since: previousLine.new_line + 1,
      to: newLine,
      bottom: true,
    },
    rest,
  );
}

export function unlinkFile() {
  if (!this.linkedFile) return;
  this[types.SET_LINKED_FILE_HASH](null);
  const newUrl = new URL(window.location);
  newUrl.searchParams.delete('file');
  newUrl.hash = '';
  window.history.replaceState(null, undefined, newUrl);
}

export function toggleAllDiffDiscussions() {
  this[types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](!this.allDiffDiscussionsExpanded);
}

export function expandAllFiles() {
  this[types.SET_COLLAPSED_STATE_FOR_ALL_FILES]({ collapsed: false });
}

export function collapseAllFiles() {
  this[types.SET_COLLAPSED_STATE_FOR_ALL_FILES]({ collapsed: true });
}
