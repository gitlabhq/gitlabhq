import { defineStore } from 'pinia';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import mrNotes from '~/mr_notes/stores';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

export const useLegacyDiffs = defineStore('legacyDiffs', {
  syncWith: {
    store: mrNotes,
    namespace: 'diffs',
  },
  state() {
    return {
      isLoading: true,
      isTreeLoaded: false,
      batchLoadingState: null,
      retrievingBatches: false,
      addedLines: null,
      removedLines: null,
      endpoint: '',
      endpointBatch: '',
      endpointMetadata: '',
      endpointCoverage: '',
      endpointUpdateUser: '',
      endpointDiffForPath: '',
      perPage: undefined,
      basePath: '',
      commit: null,
      startVersion: null, // Null unless a target diff is selected for comparison that is not the "base" diff
      diffFiles: [],
      coverageFiles: {},
      coverageLoaded: false,
      mergeRequestDiffs: [],
      mergeRequestDiff: null,
      diffViewType: INLINE_DIFF_VIEW_TYPE,
      tree: [],
      treeEntries: {},
      showTreeList: true,
      currentDiffFileId: '',
      projectPath: '',
      viewedDiffFileIds: {},
      commentForms: [],
      highlightedRow: null,
      renderTreeList: true,
      showWhitespace: true,
      viewDiffsFileByFile: false,
      fileFinderVisible: false,
      dismissEndpoint: '',
      showSuggestPopover: true,
      defaultSuggestionCommitMessage: '',
      mrReviews: {},
      latestDiff: true,
      disableVirtualScroller: false,
      linkedFileHash: null,
    };
  },
  actions: {
    ...mutations,
    ...actions,
  },
  getters,
});
