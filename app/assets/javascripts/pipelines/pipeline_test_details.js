import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import TestReports from './components/test_reports/test_reports.vue';
import createTestReportsStore from './stores/test_reports';

Vue.use(Translate);

export const createTestDetails = (selector) => {
  const el = document.querySelector(selector);
  const { blobPath, emptyStateImagePath, hasTestReport, summaryEndpoint, suiteEndpoint } =
    el?.dataset || {};
  const testReportsStore = createTestReportsStore({
    blobPath,
    summaryEndpoint,
    suiteEndpoint,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      TestReports,
    },
    provide: {
      emptyStateImagePath,
      hasTestReport: parseBoolean(hasTestReport),
    },
    store: testReportsStore,
    render(createElement) {
      return createElement('test-reports');
    },
  });
};
