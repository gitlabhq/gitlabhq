import eventHub from '~/notes/event_hub';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { initDiscussionCounter } from '~/mr_notes/discussion_counter';
import { initOverviewTabCounter } from '~/mr_notes/init_count';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { pinia } from '~/pinia/instance';

export function initMrStateLazyLoad(createRapidDiffsApp) {
  useBatchComments(pinia).$patch({ isMergeRequest: true });
  useMrNotes(pinia).setActiveTab(window.mrTabs.getCurrentAction());

  let pageInitialized = false;
  const initPage = () => {
    if (pageInitialized) return;

    // prevent loading MR state on commits and pipelines pages
    // this is due to them having a shared controller with the Overview page
    if (['diffs', 'show'].includes(useMrNotes(pinia).activeTab)) {
      eventHub.$once('fetchNotesData', () =>
        useNotes()
          .fetchNotes()
          .catch((error) =>
            createAlert({
              message: __('Something went wrong while fetching comments. Please try again.'),
              captureError: true,
              error,
            }),
          ),
      );
      eventHub.$once('fetchedNotesData', () => initOverviewTabCounter());

      const store = createRapidDiffsApp ? useMergeRequestDiscussions(pinia) : useMrNotes(pinia);
      requestIdleCallback(() => {
        initDiscussionCounter(store);
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
