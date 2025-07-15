import { parseBoolean, getCookie } from '~/lib/utils/common_utils';
import store from '~/mr_notes/stores';
import { getLocationHash, getParameterValues } from '~/lib/utils/url_utility';
import eventHub from '~/notes/event_hub';
import { initDiscussionCounter } from '~/mr_notes/discussion_counter';
import { initOverviewTabCounter } from '~/mr_notes/init_count';
import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { getReviewsForMergeRequest } from '~/diffs/utils/file_reviews';
import { DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useBatchComments } from '~/batch_comments/store';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { pinia } from '~/pinia/instance';

function setupMrNotesState(notesDataset, diffsDataset = {}) {
  const noteableData = JSON.parse(notesDataset.noteableData);
  noteableData.noteableType = notesDataset.noteableType;
  noteableData.targetType = notesDataset.targetType;
  noteableData.discussion_locked = parseBoolean(notesDataset.isLocked);
  const notesData = JSON.parse(notesDataset.notesData);
  const currentUserData = JSON.parse(notesDataset.currentUserData);
  const endpoints = { metadata: notesDataset.endpointMetadata };

  const { mrPath } = getDerivedMergeRequestInformation({ endpoint: diffsDataset.endpoint });

  store.dispatch('setNotesData', notesData);
  store.dispatch('setNoteableData', noteableData);
  store.dispatch('setUserData', currentUserData);
  store.dispatch('setTargetNoteHash', getLocationHash());
  useMrNotes(pinia).setEndpoints(endpoints);
  useLegacyDiffs(pinia).setBaseConfig({
    endpoint: diffsDataset.endpoint,
    endpointMetadata: diffsDataset.endpointMetadata,
    endpointBatch: diffsDataset.endpointBatch,
    endpointDiffForPath: diffsDataset.endpointDiffForPath,
    endpointCoverage: diffsDataset.endpointCoverage,
    endpointUpdateUser: diffsDataset.updateCurrentUserPath,
    projectPath: diffsDataset.projectPath,
    dismissEndpoint: diffsDataset.dismissEndpoint,
    showSuggestPopover: parseBoolean(diffsDataset.showSuggestPopover),
    viewDiffsFileByFile: parseBoolean(diffsDataset.fileByFileDefault),
    defaultSuggestionCommitMessage: diffsDataset.defaultSuggestionCommitMessage,
    mrReviews: getReviewsForMergeRequest(mrPath),
    diffViewType:
      getParameterValues('view')[0] || getCookie(DIFF_VIEW_COOKIE_NAME) || INLINE_DIFF_VIEW_TYPE,
    perPage: Number(diffsDataset.perPage),
  });
}

export function initMrStateLazyLoad() {
  // Pinia stores must be initialized manually during migration, otherwise they won't sync with Vuex
  useNotes(pinia);
  useLegacyDiffs(pinia);
  useBatchComments(pinia).$patch({ isMergeRequest: true });
  useMrNotes(pinia).setActiveTab(window.mrTabs.getCurrentAction());

  let pageInitialized = false;
  const initPage = () => {
    if (pageInitialized) return;

    // prevent loading MR state on commits and pipelines pages
    // this is due to them having a shared controller with the Overview page
    if (['diffs', 'show'].includes(useMrNotes(pinia).activeTab)) {
      eventHub.$once('fetchNotesData', () => store.dispatch('fetchNotes'));

      requestIdleCallback(() => {
        initOverviewTabCounter();
        initDiscussionCounter();
      });
      pageInitialized = true;
    }
  };

  window.mrTabs.eventHub.$on('MergeRequestTabChange', (value) => {
    useMrNotes(pinia).setActiveTab(value);
    initPage();
  });

  const discussionsEl = document.getElementById('js-vue-mr-discussions');
  const diffsEl = document.getElementById('js-diffs-app');

  setupMrNotesState(discussionsEl.dataset, diffsEl?.dataset);
  initPage();
}
