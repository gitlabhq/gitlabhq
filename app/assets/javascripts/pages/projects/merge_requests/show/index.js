import { hasVueMRDiscussionsCookie } from '~/lib/utils/common_utils';
import initMrNotes from '~/mr_notes';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();

  if (hasVueMRDiscussionsCookie()) {
    initMrNotes();
  }
});
