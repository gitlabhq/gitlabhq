import initMrNotes from '~/mr_notes';
import { initReviewBar } from '~/batch_comments';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';
import initIssuableHeaderWarning from '~/vue_shared/components/issuable/init_issuable_header_warning';
import store from '~/mr_notes/stores';

initShow();
if (gon.features && !gon.features.vueIssuableSidebar) {
  initSidebarBundle();
}
initMrNotes();
initReviewBar();
initIssuableHeaderWarning(store);
