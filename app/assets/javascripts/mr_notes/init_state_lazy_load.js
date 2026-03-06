import eventHub from '~/notes/event_hub';
import { initDiscussionCounter } from '~/mr_notes/discussion_counter';
import { initOverviewTabCounter } from '~/mr_notes/init_count';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { pinia } from '~/pinia/instance';

export function initMrStateLazyLoad() {
  useBatchComments(pinia).$patch({ isMergeRequest: true });
  useMrNotes(pinia).setActiveTab(window.mrTabs.getCurrentAction());

  let pageInitialized = false;
  const initPage = () => {
    if (pageInitialized) return;

    // prevent loading MR state on commits and pipelines pages
    // this is due to them having a shared controller with the Overview page
    if (['diffs', 'show'].includes(useMrNotes(pinia).activeTab)) {
      eventHub.$once('fetchNotesData', () => useNotes().fetchNotes());
      eventHub.$once('fetchedNotesData', () => initOverviewTabCounter());

      requestIdleCallback(() => {
        initDiscussionCounter();
      });
      pageInitialized = true;
    }
  };

  window.mrTabs.eventHub.$on('MergeRequestTabChange', (value) => {
    useMrNotes(pinia).setActiveTab(value);
    initPage();
  });

  initPage();
}
