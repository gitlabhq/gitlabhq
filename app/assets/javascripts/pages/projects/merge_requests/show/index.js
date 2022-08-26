import Vue from 'vue';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';
import { initReviewBar } from '~/batch_comments';
import { initIssuableHeaderWarnings } from '~/issuable';
import initMrNotes from '~/mr_notes';
import store from '~/mr_notes/stores';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';
import getStateQuery from '../queries/get_state.query.graphql';

initMrNotes();
initShow();

requestIdleCallback(() => {
  initSidebarBundle(store);
  initReviewBar();
  initIssuableHeaderWarnings(store);

  const el = document.getElementById('js-merge-sticky-header');

  if (el) {
    const { data } = el.dataset;
    const { iid, projectPath, title, tabs } = JSON.parse(data);

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      provide: {
        query: getStateQuery,
        iid,
        projectPath,
        title,
        tabs,
      },
      render(h) {
        return h(StickyHeader);
      },
    });
  }
});
