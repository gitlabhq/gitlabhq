import Vue from 'vue';
import VueApollo from 'vue-apollo';
import initMrNotes from 'ee_else_ce/mr_notes';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';
import { initIssuableHeaderWarnings } from '~/issuable';
import { start as startCodeReviewMessaging } from '~/code_review/signals';
import diffsEventHub from '~/diffs/event_hub';
import store from '~/mr_notes/stores';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import initShow from './init_merge_request_show';
import getStateQuery from './queries/get_state.query.graphql';

Vue.use(VueApollo);

export function initMrPage() {
  initMrNotes();
  initShow();
  startCodeReviewMessaging({ signalBus: diffsEventHub });
}

requestIdleCallback(() => {
  initSidebarBundle(store);
  initIssuableHeaderWarnings(store);

  const el = document.getElementById('js-merge-sticky-header');

  if (el) {
    const { data } = el.dataset;
    const { iid, projectPath, title, tabs, isFluidLayout } = JSON.parse(data);

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      apolloProvider,
      provide: {
        query: getStateQuery,
        iid,
        projectPath,
        title,
        tabs,
        isFluidLayout: parseBoolean(isFluidLayout),
      },
      render(h) {
        return h(StickyHeader);
      },
    });
  }
});
