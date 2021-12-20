import { initReviewBar } from '~/batch_comments';
import { initIssuableHeaderWarnings } from '~/issuable';
import initMrNotes from '~/mr_notes';
import store from '~/mr_notes/stores';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';

initMrNotes();
initShow();

requestIdleCallback(() => {
  initSidebarBundle(store);
  initReviewBar();
  initIssuableHeaderWarnings(store);
});
