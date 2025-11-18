import Vue from 'vue';
import VueApollo from 'vue-apollo';
import initMrNotes from 'ee_else_ce/mr_notes';
import { start as startCodeReviewMessaging } from '~/code_review/signals';
import diffsEventHub from '~/diffs/event_hub';
import { EVT_MR_DIFF_GENERATED } from '~/diffs/constants';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initMrMoreDropdown } from '~/mr_more_dropdown';
import { pinia } from '~/pinia/instance';
import ReviewDrawer from '~/batch_comments/components/review_drawer.vue';
import initShow from './init_merge_request_show';
import getStateQuery from './queries/get_state.query.graphql';

Vue.use(VueApollo);

const tabData = Vue.observable({
  tabs: [],
});

const initMrStickyHeader = () => {
  const el = document.getElementById('js-merge-sticky-header');

  if (el && !CSS.supports('container-type: scroll-state')) {
    const { data } = el.dataset;

    let parsedData;

    try {
      parsedData = JSON.parse(data);
    } catch {
      parsedData = {};
    }

    const {
      iid,
      canResolveDiscussion,
      projectPath,
      title,
      tabs,
      defaultBranchName,
      isFluidLayout,
      sourceProjectPath,
      blocksMerge,
      imported,
      isDraft,
    } = parsedData;

    tabData.tabs = tabs;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      name: 'MergeRequestStickyHeaderRoot',
      pinia,
      apolloProvider,
      components: {
        StickyHeader: () => import('~/merge_requests/components/sticky_header.vue'),
      },
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
        return h('sticky-header', {
          props: {
            tabs: tabData.tabs,
            canResolveDiscussion: parseBoolean(canResolveDiscussion),
            isImported: parseBoolean(imported),
            isDraft: parseBoolean(isDraft),
          },
        });
      },
    });
  }
};

const initReviewDrawer = () => {
  // Review drawer has to be located outside the MR sticky/non-sticky header
  // Otherwise it will disappear when header switches between sticky/non-sticky components
  const el = document.querySelector('#js-review-drawer');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    apolloProvider,
    provide: {
      newCommentTemplatePaths: JSON.parse(el.dataset.newCommentTemplatePaths),
      canSummarize: parseBoolean(el.dataset.canSummarize),
    },
    render(h) {
      return h(ReviewDrawer);
    },
  });
};

export function initMrPage(createRapidDiffsApp) {
  initMrNotes(createRapidDiffsApp);
  initShow();
  initMrMoreDropdown();
  startCodeReviewMessaging({ signalBus: diffsEventHub });

  const changesCountBadge = document.querySelector('.js-changes-tab-count');
  const commitsCountBadge = document.querySelector('.js-commits-count .gl-badge-content');
  diffsEventHub.$on(EVT_MR_DIFF_GENERATED, (mergeRequestDiffGenerated) => {
    const { diffStatsSummary: { fileCount = null } = {}, commitCount } = mergeRequestDiffGenerated;

    if (changesCountBadge.textContent === '-' && fileCount !== null) {
      changesCountBadge.textContent = fileCount;

      const DIFF_TAB_INDEX = 3;
      const diffTab = tabData.tabs ? tabData.tabs[tabData.tabs.length - 1] : [];

      const hasDiffTab = diffTab?.length >= DIFF_TAB_INDEX + 1;
      if (hasDiffTab) {
        diffTab[DIFF_TAB_INDEX] = fileCount;
      }
    }

    if (commitsCountBadge?.textContent === '-' && commitCount !== null) {
      commitsCountBadge.textContent = commitCount;
    }
  });

  requestIdleCallback(() => {
    initSidebarBundle();
    initMrStickyHeader();
    initReviewDrawer();
  });
}
