import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import TestReports from './components/test_reports/test_reports.vue';

Vue.use(Vuex);
Vue.use(Translate);

export const createTestDetails = (selector) => {
  const el = document.querySelector(selector);
  const {
    blobPath,
    emptyStateImagePath,
    hasTestReport,
    summaryEndpoint,
    suiteEndpoint,
    artifactsExpiredImagePath,
  } = el?.dataset || {};

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      TestReports,
    },
    provide: {
      emptyStateImagePath,
      artifactsExpiredImagePath,
      hasTestReport: parseBoolean(hasTestReport),
      blobPath,
      summaryEndpoint,
      suiteEndpoint,
    },
    store: new Vuex.Store(),
    render(createElement) {
      return createElement('test-reports');
    },
  });
};
