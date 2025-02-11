<script>
import { GlLoadingIcon, GlPagination, GlSprintf, GlAlert } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce, throttle } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import FindingsDrawer from 'ee_component/diffs/components/shared/findings_drawer.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import api from '~/api';
import {
  keysFor,
  MR_PREVIOUS_FILE_IN_DIFF,
  MR_NEXT_FILE_IN_DIFF,
  MR_COMMITS_NEXT_COMMIT,
  MR_COMMITS_PREVIOUS_COMMIT,
} from '~/behaviors/shortcuts/keybindings';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import { parseBoolean, handleLocationHash } from '~/lib/utils/common_utils';
import { BV_HIDE_TOOLTIP, DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { Mousetrap } from '~/lib/mousetrap';
import { updateHistory, getLocationHash } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import notesEventHub from '~/notes/event_hub';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import getMRCodequalityAndSecurityReports from 'ee_else_ce/diffs/components/graphql/get_mr_codequality_and_security_reports.query.graphql';
import { sortFindingsByFile } from '../utils/sort_findings_by_file';
import {
  MR_TREE_SHOW_KEY,
  ALERT_OVERFLOW_HIDDEN,
  ALERT_MERGE_CONFLICT,
  ALERT_COLLAPSED_FILES,
  INLINE_DIFF_VIEW_TYPE,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_FILE_BROWSER_TREE,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_WHITESPACE_SHOW,
  TRACKING_WHITESPACE_HIDE,
  TRACKING_SINGLE_FILE_MODE,
  TRACKING_MULTIPLE_FILES_MODE,
  EVT_MR_PREPARED,
  EVT_DISCUSSIONS_ASSIGNED,
} from '../constants';

import { isCollapsed } from '../utils/diff_file';
import diffsEventHub from '../event_hub';
import { reviewStatuses } from '../utils/file_reviews';
import { diffsApp } from '../utils/performance';
import { updateChangesTabCount, extractFileHash } from '../utils/merge_request';
import { queueRedisHllEvents } from '../utils/queue_events';
import CollapsedFilesWarning from './collapsed_files_warning.vue';
import CommitWidget from './commit_widget.vue';
import CompareVersions from './compare_versions.vue';
import DiffFile from './diff_file.vue';
import HiddenFilesWarning from './hidden_files_warning.vue';
import NoChanges from './no_changes.vue';
import VirtualScrollerScrollSync from './virtual_scroller_scroll_sync';
import DiffsFileTree from './diffs_file_tree.vue';
import DiffAppControls from './diff_app_controls.vue';

export const FINDINGS_STATUS_PARSED = 'PARSED';
export const FINDINGS_STATUS_ERROR = 'ERROR';
export const FINDINGS_POLL_INTERVAL = 1000;

export default {
  name: 'DiffsApp',
  FINDINGS_STATUS_PARSED,
  FINDINGS_STATUS_ERROR,
  components: {
    DiffAppControls,
    DiffsFileTree,
    FindingsDrawer,
    DynamicScroller,
    DynamicScrollerItem,
    VirtualScrollerScrollSync,
    CompareVersions,
    DiffFile,
    NoChanges,
    HiddenFilesWarning,
    CollapsedFilesWarning,
    CommitWidget,
    GlLoadingIcon,
    GlPagination,
    GlSprintf,
    GlAlert,
  },
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
  alerts: {
    ALERT_OVERFLOW_HIDDEN,
    ALERT_MERGE_CONFLICT,
    ALERT_COLLAPSED_FILES,
  },
  props: {
    endpointCoverage: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    iid: {
      type: String,
      required: false,
      default: '',
    },
    sastReportAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    codequalityReportAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    endpointCodequality: {
      type: String,
      required: false,
      default: '',
    },
    shouldShow: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUser: {
      type: Object,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    changesEmptyStateIllustration: {
      type: String,
      required: false,
      default: '',
    },
    linkedFileUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      diffFilesLength: 0,
      virtualScrollCurrentIndex: -1,
      subscribedToVirtualScrollingEvents: false,
      autoScrolled: false,
      activeProject: undefined,
      hasScannerError: false,
      linkedFileStatus: '',
      codequalityData: {},
      sastData: {},
      keydownTime: undefined,
      listenersAttached: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    getMRCodequalityAndSecurityReports: {
      query: getMRCodequalityAndSecurityReports,
      pollInterval: FINDINGS_POLL_INTERVAL,
      variables() {
        return { fullPath: this.projectPath, iid: this.iid };
      },
      skip() {
        if (this.hasScannerError) {
          return true;
        }

        return !this.codequalityReportAvailable && !this.sastReportAvailable;
      },
      update(data) {
        if (!data?.project?.mergeRequest) {
          return;
        }

        const { codequalityReportsComparer, sastReport } = data.project.mergeRequest;
        this.activeProject = data.project.mergeRequest.project;

        if (
          (sastReport?.status === FINDINGS_STATUS_PARSED || !this.sastReportAvailable) &&
          (!this.codequalityReportAvailable ||
            codequalityReportsComparer.status === FINDINGS_STATUS_PARSED)
        ) {
          this.$apollo.queries.getMRCodequalityAndSecurityReports.stopPolling();
        }

        if (sastReport?.status === FINDINGS_STATUS_ERROR && this.sastReportAvailable) {
          this.fetchScannerFindingsError();

          this.$apollo.queries.getMRCodequalityAndSecurityReports.stopPolling();
        }

        if (codequalityReportsComparer?.report?.newErrors) {
          this.codequalityData = sortFindingsByFile(codequalityReportsComparer.report.newErrors);
        }

        if (sastReport?.report) {
          this.sastData = sastReport.report;
        }
      },
      error() {
        this.fetchScannerFindingsError();
        this.$apollo.queries.getMRCodequalityAndSecurityReports.stopPolling();
      },
    },
  },
  computed: {
    ...mapState('diffs', {
      numTotalFiles: 'realSize',
      numVisibleFiles: 'size',
    }),
    ...mapState('findingsDrawer', ['activeDrawer']),
    ...mapState('diffs', [
      'isLoading',
      'diffViewType',
      'commit',
      'renderOverflowWarning',
      'plainDiffPath',
      'emailPatchPath',
      'retrievingBatches',
      'startVersion',
      'latestDiff',
      'currentDiffFileId',
      'isTreeLoaded',
      'conflictResolutionPath',
      'canMerge',
      'hasConflicts',
      'viewDiffsFileByFile',
      'mrReviews',
      'renderTreeList',
      'showWhitespace',
      'targetBranchName',
      'branchName',
      'showTreeList',
      'addedLines',
      'removedLines',
    ]),
    ...mapGetters('diffs', [
      'whichCollapsedTypes',
      'isParallelView',
      'currentDiffIndex',
      'isVirtualScrollingEnabled',
      'isBatchLoading',
      'isBatchLoadingError',
      'flatBlobsList',
      'diffFiles',
    ]),
    ...mapGetters(['isNotesFetched', 'getNoteableData']),
    ...mapGetters('findingsDrawer', ['activeDrawer']),
    diffs() {
      if (!this.viewDiffsFileByFile) {
        return this.diffFiles;
      }

      return this.diffFiles.filter((file, i) => {
        return file.file_hash === this.currentDiffFileId || (i === 0 && !this.currentDiffFileId);
      });
    },
    canCurrentUserFork() {
      return this.currentUser.can_fork === true && this.currentUser.can_create_merge_request;
    },
    renderDiffFiles() {
      return this.flatBlobsList.length > 0;
    },
    diffsIncomplete() {
      return this.flatBlobsList.length !== this.diffFiles.length;
    },
    isFullChangeset() {
      return this.startVersion === null && this.latestDiff;
    },
    showFileByFileNavigation() {
      return this.flatBlobsList.length > 1 && this.viewDiffsFileByFile;
    },
    currentFileNumber() {
      return this.currentDiffIndex + 1;
    },
    previousFileNumber() {
      const { currentDiffIndex } = this;

      return currentDiffIndex >= 1 ? currentDiffIndex : null;
    },
    nextFileNumber() {
      const { currentFileNumber, flatBlobsList } = this;

      return currentFileNumber < flatBlobsList.length ? currentFileNumber + 1 : null;
    },
    visibleWarning() {
      let visible = false;

      if (this.renderOverflowWarning) {
        visible = this.$options.alerts.ALERT_OVERFLOW_HIDDEN;
      } else if (this.isFullChangeset && this.hasConflicts) {
        visible = this.$options.alerts.ALERT_MERGE_CONFLICT;
      } else if (this.whichCollapsedTypes.automatic && !this.viewDiffsFileByFile) {
        visible = this.$options.alerts.ALERT_COLLAPSED_FILES;
      }

      return visible;
    },
    fileReviews() {
      return reviewStatuses(this.diffFiles, this.mrReviews);
    },
    resourceId() {
      return convertToGraphQLId('MergeRequest', this.getNoteableData.id);
    },
    renderFileTree() {
      return this.renderDiffFiles && this.showTreeList;
    },
    hideTooltips() {
      const hide = () => {
        if (!this.shouldShow) return;
        this.$root.$emit(BV_HIDE_TOOLTIP);
      };
      return throttle(hide, 100);
    },
    hasChanges() {
      return this.diffFiles.length > 0;
    },
  },
  watch: {
    commit(newCommit, oldCommit) {
      const commitChangedAfterRender = newCommit && !this.isLoading;
      const commitIsDifferent = oldCommit && newCommit.id !== oldCommit.id;
      const url = window?.location ? String(window.location) : '';

      if (commitChangedAfterRender && commitIsDifferent) {
        updateHistory({
          title: document.title,
          url: url.replace(oldCommit.id, newCommit.id),
        });
        this.refetchDiffData();
        this.adjustView();
      }
    },
    diffViewType() {
      this.adjustView();
    },
    viewDiffsFileByFile(newViewFileByFile) {
      if (!newViewFileByFile && this.diffsIncomplete) {
        this.refetchDiffData({ refetchMeta: false });
      }
    },
    shouldShow() {
      // When the shouldShow property changed to true, the route is rendered for the first time
      // and if we have the isLoading as true this means we didn't fetch the data
      if (this.isLoading) {
        this.fetchData();
      }

      this.adjustView();
      this.subscribeToVirtualScrollingEvents();
    },
    renderFileTree: 'adjustView',
    isLoading: 'adjustView',
  },
  mounted() {
    if (this.shouldShow) {
      this.fetchData();
    }

    const id = window?.location?.hash;

    if (id && id.indexOf('#note') !== 0) {
      this.setHighlightedRow({ lineCode: id.split('diff-content').pop().slice(1) });
    }

    const events = [];

    if (this.renderTreeList) {
      events.push(TRACKING_FILE_BROWSER_TREE);
    } else {
      events.push(TRACKING_FILE_BROWSER_LIST);
    }

    if (this.diffViewType === INLINE_DIFF_VIEW_TYPE) {
      events.push(TRACKING_DIFF_VIEW_INLINE);
    } else {
      events.push(TRACKING_DIFF_VIEW_PARALLEL);
    }

    if (this.showWhitespace) {
      events.push(TRACKING_WHITESPACE_SHOW);
    } else {
      events.push(TRACKING_WHITESPACE_HIDE);
    }

    if (this.viewDiffsFileByFile) {
      events.push(TRACKING_SINGLE_FILE_MODE);
    } else {
      events.push(TRACKING_MULTIPLE_FILES_MODE);
    }

    queueRedisHllEvents(events, { verifyCap: true });

    this.subscribeToVirtualScrollingEvents();
    window.addEventListener('hashchange', this.handleHashChange);
    window.addEventListener('scroll', this.hideTooltips);
  },
  beforeCreate() {
    diffsApp.instrument();
  },
  created() {
    this.adjustView();
    this.subscribeToEvents();

    this.slowHashHandler = debounce(() => {
      handleLocationHash();
      this.autoScrolled = true;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    this.$watch(
      () => this.$store.state.notes.discussions.length,
      (newVal, prevVal) => {
        if (newVal > prevVal) {
          this.setDiscussions();
        }
      },
    );
  },
  beforeDestroy() {
    diffsApp.deinstrument();
    this.unsubscribeFromEvents();
    this.removeEventListeners();

    window.removeEventListener('hashchange', this.handleHashChange);
    window.removeEventListener('scroll', this.hideTooltips);

    diffsEventHub.$off('scrollToFileHash', this.scrollVirtualScrollerToFileHash);
    diffsEventHub.$off('scrollToIndex', this.scrollVirtualScrollerToIndex);
  },
  methods: {
    ...mapActions(['startTaskList']),
    ...mapActions('diffs', [
      'moveToNeighboringCommit',
      'fetchDiffFilesMeta',
      'fetchDiffFilesBatch',
      'fetchFileByFile',
      'loadCollapsedDiff',
      'setFileForcedOpen',
      'fetchCoverageFiles',
      'rereadNoteHash',
      'startRenderDiffsQueue',
      'assignDiscussionsToDiff',
      'setCurrentFileHash',
      'setHighlightedRow',
      'goToFile',
      'setShowTreeList',
      'navigateToDiffFileIndex',
      'setFileByFile',
      'disableVirtualScroller',
      'fetchLinkedFile',
      'toggleTreeList',
      'expandAllFiles',
      'collapseAllFiles',
      'setDiffViewType',
      'setShowWhitespace',
      'goToFile',
    ]),
    ...mapActions('findingsDrawer', ['setDrawer']),
    closeDrawer() {
      this.setDrawer({});
    },
    fetchScannerFindingsError() {
      this.hasScannerError = true;
      createAlert({
        message: __('Something went wrong fetching the scanner findings. Please try again.'),
      });
    },
    subscribeToEvents() {
      notesEventHub.$once('fetchDiffData', this.fetchData);
      notesEventHub.$on('refetchDiffData', this.refetchDiffData);
      notesEventHub.$on('fetchedNotesData', this.rereadNoteHash);
      notesEventHub.$on('noteFormAddToReview', this.handleReviewTracking);
      notesEventHub.$on('noteFormStartReview', this.handleReviewTracking);
      diffsEventHub.$on('diffFilesModified', this.setDiscussions);
      diffsEventHub.$on('doneLoadingBatches', this.autoScroll);
      diffsEventHub.$on(EVT_MR_PREPARED, this.fetchData);
      diffsEventHub.$on(EVT_DISCUSSIONS_ASSIGNED, this.handleHash);
    },
    unsubscribeFromEvents() {
      diffsEventHub.$off(EVT_DISCUSSIONS_ASSIGNED, this.handleHash);
      diffsEventHub.$off(EVT_MR_PREPARED, this.fetchData);
      diffsEventHub.$off('doneLoadingBatches', this.autoScroll);
      diffsEventHub.$off('diffFilesModified', this.setDiscussions);
      notesEventHub.$off('noteFormStartReview', this.handleReviewTracking);
      notesEventHub.$off('noteFormAddToReview', this.handleReviewTracking);
      notesEventHub.$off('fetchedNotesData', this.rereadNoteHash);
      notesEventHub.$off('refetchDiffData', this.refetchDiffData);
      notesEventHub.$off('fetchDiffData', this.fetchData);
    },
    autoScroll() {
      const lineCode = window.location.hash;
      const sha1InHash = extractFileHash({ input: lineCode });

      if (sha1InHash) {
        const idx = this.diffs.findIndex((diffFile) => diffFile.file_hash === sha1InHash);
        const file = this.diffs[idx];

        if (!isCollapsed(file)) return;

        this.loadCollapsedDiff({ file })
          .then(() => {
            this.setDiscussions();
            this.setFileForcedOpen({ filePath: file.new_path });

            this.$nextTick(() => this.scrollVirtualScrollerToIndex(idx));
          })
          .catch(() => {});
      }
    },
    handleHash() {
      if (this.viewDiffsFileByFile && !this.autoScrolled) {
        const file = this.diffs[0];

        if (file && !file.isLoadingFullFile) {
          requestIdleCallback(() => this.slowHashHandler());
        }
      }
    },
    handleHashChange() {
      let hash = getLocationHash();

      if (this.viewDiffsFileByFile) {
        if (!hash) {
          hash = this.diffFiles[0].file_hash;
        }

        this.setCurrentFileHash(hash);
        this.fetchFileByFile();
      }
    },
    navigateToDiffFileNumber(number) {
      this.navigateToDiffFileIndex(number - 1);
    },
    refetchDiffData({ refetchMeta = true } = {}) {
      this.fetchData({ toggleTree: false, fetchMeta: refetchMeta });
    },
    fetchData({ toggleTree = true, fetchMeta = true } = {}) {
      if (this.linkedFileUrl && this.linkedFileStatus !== 'loaded') {
        this.linkedFileStatus = 'loading';
        this.fetchLinkedFile(this.linkedFileUrl)
          .then(() => {
            this.linkedFileStatus = 'loaded';
            if (toggleTree) this.setTreeDisplay();
          })
          .catch(() => {
            this.linkedFileStatus = 'error';
            createAlert({
              message: __("Couldn't fetch the linked file."),
            });
          });
      }
      if (fetchMeta) {
        this.fetchDiffFilesMeta()
          .then((data) => {
            let realSize = 0;

            if (data) {
              realSize = data.real_size;

              if (this.viewDiffsFileByFile) {
                this.fetchFileByFile();
              }
            }

            this.diffFilesLength = parseInt(realSize, 10) || 0;
            if (toggleTree) {
              this.setTreeDisplay();
            }

            updateChangesTabCount({
              count: this.diffFilesLength,
            });
          })
          .catch(() => {
            createAlert({
              message: __('Something went wrong on our end. Please try again.'),
            });
          });
      }

      if (!this.viewDiffsFileByFile) {
        this.fetchDiffFilesBatch(Boolean(this.linkedFileUrl))
          .then(() => {
            if (toggleTree) this.setTreeDisplay();
            // Guarantee the discussions are assigned after the batch finishes.
            // Just watching the length of the discussions or the diff files
            // isn't enough, because with split diff loading, neither will
            // change when loading the other half of the diff files.
            this.setDiscussions();
          })
          .catch(() => {
            createAlert({
              message: __('Something went wrong on our end. Please try again.'),
            });
          });
      }

      if (this.endpointCoverage) {
        this.fetchCoverageFiles();
      }

      if (!this.isNotesFetched) {
        notesEventHub.$emit('fetchNotesData');
      }
    },
    setDiscussions() {
      requestIdleCallback(
        () =>
          this.assignDiscussionsToDiff()
            .then(this.$nextTick)
            .then(this.startTaskList)
            .then(this.scrollVirtualScrollerToDiffNote),
        { timeout: 1000 },
      );
    },
    adjustView() {
      if (this.shouldShow) {
        this.$nextTick(() => {
          this.setEventListeners();
        });
      } else {
        this.removeEventListeners();
      }
    },
    setEventListeners() {
      if (this.listenersAttached) return;

      Mousetrap.bind(keysFor(MR_PREVIOUS_FILE_IN_DIFF), () => this.jumpToFile(-1));
      Mousetrap.bind(keysFor(MR_NEXT_FILE_IN_DIFF), () => this.jumpToFile(+1));

      if (this.commit) {
        Mousetrap.bind(keysFor(MR_COMMITS_NEXT_COMMIT), () =>
          this.moveToNeighboringCommit({ direction: 'next' }),
        );
        Mousetrap.bind(keysFor(MR_COMMITS_PREVIOUS_COMMIT), () =>
          this.moveToNeighboringCommit({ direction: 'previous' }),
        );
      }

      Mousetrap.bind(['mod+f', 'mod+g'], () => {
        this.keydownTime = new Date().getTime();
      });

      window.addEventListener('blur', this.handleBrowserFindActivation);

      this.listenersAttached = true;
    },
    removeEventListeners() {
      Mousetrap.unbind(keysFor(MR_PREVIOUS_FILE_IN_DIFF));
      Mousetrap.unbind(keysFor(MR_NEXT_FILE_IN_DIFF));
      Mousetrap.unbind(keysFor(MR_COMMITS_NEXT_COMMIT));
      Mousetrap.unbind(keysFor(MR_COMMITS_PREVIOUS_COMMIT));
      Mousetrap.unbind(['ctrl+f', 'command+f', 'mod+f', 'mod+g']);
      window.removeEventListener('blur', this.handleBrowserFindActivation);
      this.listenersAttached = false;
    },
    handleBrowserFindActivation() {
      if (!this.keydownTime) return;

      const delta = new Date().getTime() - this.keydownTime;

      // To make sure the user is using the find function we need to wait for blur
      // and max 1000ms to be sure it the search box is filtered
      if (delta >= 0 && delta < 1000) {
        this.disableVirtualScroller();

        api.trackRedisHllUserEvent('i_code_review_user_searches_diff');
        api.trackRedisCounterEvent('diff_searches');
      }
    },
    jumpToFile(step) {
      const targetIndex = this.currentDiffIndex + step;
      if (targetIndex >= 0 && targetIndex < this.flatBlobsList.length) {
        this.goToFile({ path: this.flatBlobsList[targetIndex].path });
      }
    },
    setTreeDisplay() {
      const storedTreeShow = localStorage.getItem(MR_TREE_SHOW_KEY);
      let showTreeList = true;

      if (storedTreeShow !== null) {
        showTreeList = parseBoolean(storedTreeShow);
      } else if (!bp.isDesktop() || (!this.isBatchLoading && this.flatBlobsList.length <= 1)) {
        showTreeList = false;
      }

      return this.setShowTreeList({ showTreeList, saving: false });
    },
    async scrollVirtualScrollerToFileHash(hash) {
      const index = this.diffFiles.findIndex((f) => f.file_hash === hash);

      if (index !== -1) {
        this.scrollVirtualScrollerToIndex(index);
      }
    },
    scrollVirtualScrollerToIndex(index) {
      this.virtualScrollCurrentIndex = index;
    },
    scrollVirtualScrollerToDiffNote() {
      const id = window?.location?.hash;

      if (id.startsWith('#note_')) {
        const noteId = id.replace('#note_', '');
        const discussion = this.$store.state.notes.discussions.find(
          (d) => d.diff_file && d.notes.find((n) => n.id === noteId),
        );

        if (discussion) {
          this.scrollVirtualScrollerToFileHash(discussion.diff_file.file_hash);
        }
      }
    },
    subscribeToVirtualScrollingEvents() {
      if (this.shouldShow && !this.subscribedToVirtualScrollingEvents) {
        diffsEventHub.$on('scrollToFileHash', this.scrollVirtualScrollerToFileHash);
        diffsEventHub.$on('scrollToIndex', this.scrollVirtualScrollerToIndex);

        this.subscribedToVirtualScrollingEvents = true;
      }
    },
    reloadPage() {
      window.location.reload();
    },
    handleReviewTracking(event) {
      const types = {
        noteFormStartReview: 'merge_request_click_start_review_on_changes_tab',
        noteFormAddToReview: 'merge_request_click_add_to_review_on_changes_tab',
      };

      if (this.shouldShow && types[event.name]) {
        this.trackEvent(types[event.name]);
      }
    },
    fileTreeToggled() {
      this.toggleTreeList();
      this.adjustView();
    },
    isDiffViewActive(item) {
      return this.virtualScrollCurrentIndex >= 0 && this.currentDiffFileId === item.file_hash;
    },
    toggleFileByFile() {
      this.setFileByFile({ fileByFile: !this.viewDiffsFileByFile });
    },
    toggleWhitespace(updatedSetting) {
      this.setShowWhitespace({ showWhitespace: updatedSetting });
    },
  },
  howToMergeDocsPath: helpPagePath('user/project/merge_requests/merge_request_troubleshooting.md', {
    anchor: 'check-out-merge-requests-locally-through-the-head-ref',
  }),
};
</script>

<template>
  <div v-show="shouldShow">
    <findings-drawer :project="activeProject" :drawer="activeDrawer" @close="closeDrawer" />
    <div v-if="isLoading || !isTreeLoaded" class="loading"><gl-loading-icon size="lg" /></div>
    <div v-else id="diffs" :class="{ active: shouldShow }" class="diffs tab-pane">
      <div class="gl-flex gl-flex-wrap">
        <compare-versions :toggle-file-tree-visible="hasChanges" />
        <diff-app-controls
          class="gl-ml-auto"
          :has-changes="hasChanges"
          :diffs-count="numTotalFiles"
          :added-lines="addedLines"
          :removed-lines="removedLines"
          :show-whitespace="showWhitespace"
          :view-diffs-file-by-file="viewDiffsFileByFile"
          :diff-view-type="diffViewType"
          @expandAllFiles="expandAllFiles"
          @collapseAllFiles="collapseAllFiles"
          @updateDiffViewType="setDiffViewType"
          @toggleWhitespace="toggleWhitespace"
          @toggleFileByFile="toggleFileByFile"
        />
      </div>

      <template v-if="!isBatchLoadingError">
        <collapsed-files-warning v-if="visibleWarning == $options.alerts.ALERT_COLLAPSED_FILES" />
      </template>

      <div
        :data-can-create-note="getNoteableData.current_user.can_create_note"
        class="files gl-mt-2 gl-flex"
      >
        <diffs-file-tree
          :visible="renderFileTree"
          @toggled="fileTreeToggled"
          @clickFile="goToFile({ path: $event.path })"
        />
        <div class="col-12 col-md-auto diff-files-holder">
          <commit-widget v-if="commit" :commit="commit" :collapsible="false" />
          <gl-alert
            v-if="isBatchLoadingError"
            variant="danger"
            :dismissible="false"
            :primary-button-text="__('Reload page')"
            @primaryAction="reloadPage"
          >
            {{ __("Error: Couldn't load some or all of the changes.") }}
          </gl-alert>
          <div v-if="isBatchLoading && !isBatchLoadingError" class="loading">
            <gl-loading-icon size="lg" />
          </div>
          <template v-else-if="renderDiffFiles">
            <div v-if="linkedFileStatus === 'loading'" class="loading">
              <gl-loading-icon size="lg" />
            </div>
            <hidden-files-warning
              v-if="visibleWarning == $options.alerts.ALERT_OVERFLOW_HIDDEN"
              :visible="numVisibleFiles"
              :total="numTotalFiles"
              :plain-diff-path="plainDiffPath"
              :email-patch-path="emailPatchPath"
            />
            <dynamic-scroller
              v-if="isVirtualScrollingEnabled"
              :items="diffs"
              :min-item-size="70"
              :buffer="1000"
              :use-transform="false"
              page-mode
            >
              <template #default="{ item, index, active }">
                <dynamic-scroller-item
                  v-if="active"
                  :item="item"
                  :active="active"
                  :class="{ active }"
                  class="gl-mb-5"
                >
                  <diff-file
                    :file="item"
                    :codequality-data="codequalityData"
                    :sast-data="sastData"
                    :reviewed="fileReviews[item.id]"
                    :is-first-file="index === 0"
                    :is-last-file="index === diffFilesLength - 1"
                    :help-page-path="helpPagePath"
                    :can-current-user-fork="canCurrentUserFork"
                    :view-diffs-file-by-file="viewDiffsFileByFile"
                    :active="active"
                    :is-diff-view-active="isDiffViewActive(item)"
                  />
                </dynamic-scroller-item>
              </template>
              <template #before>
                <virtual-scroller-scroll-sync v-model="virtualScrollCurrentIndex" />
              </template>
            </dynamic-scroller>
            <template v-else>
              <diff-file
                v-for="(file, index) in diffs"
                :key="file.new_path"
                :file="file"
                :codequality-data="codequalityData"
                :sast-data="sastData"
                :reviewed="fileReviews[file.id]"
                :is-first-file="index === 0"
                :is-last-file="index === diffFilesLength - 1"
                :help-page-path="helpPagePath"
                :can-current-user-fork="canCurrentUserFork"
                :view-diffs-file-by-file="viewDiffsFileByFile"
                :is-diff-view-active="currentDiffFileId === file.file_hash"
                class="gl-mb-5"
              />
            </template>
            <div
              v-if="showFileByFileNavigation"
              data-testid="file-by-file-navigation"
              class="gl-grid gl-text-center"
            >
              <gl-pagination
                class="gl-mx-auto"
                :value="currentFileNumber"
                :prev-page="previousFileNumber"
                :next-page="nextFileNumber"
                @input="navigateToDiffFileNumber"
              />
              <gl-sprintf :message="__('File %{current} of %{total}')">
                <template #current>{{ currentFileNumber }}</template>
                <template #total>{{ flatBlobsList.length }}</template>
              </gl-sprintf>
            </div>
            <gl-loading-icon v-else-if="retrievingBatches" size="lg" />
          </template>
          <no-changes
            v-else-if="!isBatchLoadingError"
            :changes-empty-state-illustration="changesEmptyStateIllustration"
          />
        </div>
      </div>
    </div>
  </div>
</template>
