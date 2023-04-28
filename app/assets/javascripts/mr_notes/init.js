import { parseBoolean } from '~/lib/utils/common_utils';
import store from '~/mr_notes/stores';
import { getLocationHash } from '~/lib/utils/url_utility';
import eventHub from '~/notes/event_hub';
import { initReviewBar } from '~/batch_comments';
import { initDiscussionCounter } from '~/mr_notes/discussion_counter';
import { initOverviewTabCounter } from '~/mr_notes/init_count';

function setupMrNotesState(notesDataset) {
  const noteableData = JSON.parse(notesDataset.noteableData);
  noteableData.noteableType = notesDataset.noteableType;
  noteableData.targetType = notesDataset.targetType;
  noteableData.discussion_locked = parseBoolean(notesDataset.isLocked);
  const notesData = JSON.parse(notesDataset.notesData);
  const currentUserData = JSON.parse(notesDataset.currentUserData);
  const endpoints = { metadata: notesDataset.endpointMetadata };

  store.dispatch('setNotesData', notesData);
  store.dispatch('setNoteableData', noteableData);
  store.dispatch('setUserData', currentUserData);
  store.dispatch('setTargetNoteHash', getLocationHash());
  store.dispatch('setEndpoints', endpoints);
}

export function initMrStateLazyLoad({ reviewBarParams } = {}) {
  store.dispatch('setActiveTab', window.mrTabs.getCurrentAction());
  window.mrTabs.eventHub.$on('MergeRequestTabChange', (value) =>
    store.dispatch('setActiveTab', value),
  );

  const discussionsEl = document.getElementById('js-vue-mr-discussions');
  const notesDataset = discussionsEl.dataset;
  let stop = () => {};
  stop = store.watch(
    (state) => state.page.activeTab,
    (activeTab) => {
      setupMrNotesState(notesDataset);

      // prevent loading MR state on commits and pipelines pages
      // this is due to them having a shared controller with the Overview page
      if (['diffs', 'show'].includes(activeTab)) {
        eventHub.$once('fetchNotesData', () => store.dispatch('fetchNotes'));

        requestIdleCallback(() => {
          initReviewBar(reviewBarParams);
          initOverviewTabCounter();
          initDiscussionCounter();
        });
        stop();
      }
    },
    { immediate: true },
  );
}
