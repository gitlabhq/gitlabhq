import Vue from 'vue';
import VueApollo from 'vue-apollo';
import initMrNotes from 'ee_else_ce/mr_notes';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';
import { start as startCodeReviewMessaging } from '~/code_review/signals';
import diffsEventHub from '~/diffs/event_hub';
import { EVT_MR_DIFF_GENERATED } from '~/diffs/constants';
import store from '~/mr_notes/stores';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initMrMoreDropdown } from '~/mr_more_dropdown';
import { pinia } from '~/pinia/instance';
import initShow from './init_merge_request_show';
import getStateQuery from './queries/get_state.query.graphql';

Vue.use(VueApollo);

const tabData = Vue.observable({
  tabs: [],
});

export function initMrPage() {
  initMrNotes();
  initShow(store, pinia);
  initMrMoreDropdown();
  startCodeReviewMessaging({ signalBus: diffsEventHub });

  const changesCountBadge = document.querySelector('.js-changes-tab-count');
  diffsEventHub.$on(EVT_MR_DIFF_GENERATED, (mergeRequestDiffGenerated) => {
    const { fileCount } = mergeRequestDiffGenerated.diffStatsSummary;

    if (changesCountBadge.textContent === '-') {
      changesCountBadge.textContent = fileCount;

      const DIFF_TAB_INDEX = 3;
      const diffTab = tabData.tabs ? tabData.tabs[tabData.tabs.length - 1] : [];

      const hasDiffTab = diffTab?.length >= DIFF_TAB_INDEX + 1;
      if (hasDiffTab) {
        diffTab[DIFF_TAB_INDEX] = fileCount;
      }
    }
  });
}

requestIdleCallback(() => {
  initSidebarBundle(store, pinia);

  const el = document.getElementById('js-merge-sticky-header');

  if (el) {
    const { data } = el.dataset;

    let parsedData;

    try {
      parsedData = JSON.parse(data);
    } catch {
      parsedData = {};
    }

    const {
      iid,
      projectPath,
      title,
      tabs,
      defaultBranchName,
      isFluidLayout,
      sourceProjectPath,
      blocksMerge,
      imported,
    } = parsedData;

    tabData.tabs = tabs;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      name: 'MergeRequestStickyHeaderRoot',
      store,
      pinia,
      apolloProvider,
      provide: {
        query: getStateQuery,
        iid,
        defaultBranchName,
        projectPath,
        title,
        isFluidLayout: parseBoolean(isFluidLayout),
        blocksMerge: parseBoolean(blocksMerge),
        sourceProjectPath,
      },
      render(h) {
        return h(StickyHeader, {
          props: {
            tabs: tabData.tabs,
            isImported: parseBoolean(imported),
          },
        });
      },
    });
  }
});
