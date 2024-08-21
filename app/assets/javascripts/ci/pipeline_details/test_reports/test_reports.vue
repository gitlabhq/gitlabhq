<script>
import { GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import {
  getParameterValues,
  updateHistory,
  setUrlParams,
  removeParams,
} from '~/lib/utils/url_utility';
import EmptyState from './empty_state.vue';
import TestSuiteTable from './test_suite_table.vue';
import TestSummary from './test_summary.vue';
import TestSummaryTable from './test_summary_table.vue';

export default {
  name: 'TestReports',
  components: {
    EmptyState,
    GlLoadingIcon,
    TestSuiteTable,
    TestSummary,
    TestSummaryTable,
  },
  inject: ['blobPath', 'summaryEndpoint', 'suiteEndpoint'],
  computed: {
    ...mapState('testReports', ['isLoading', 'selectedSuiteIndex', 'testReports']),
    ...mapGetters('testReports', ['getSelectedSuite', 'getTestSuites']),
    showSuite() {
      return this.selectedSuiteIndex !== null;
    },
    showTests() {
      const { test_suites: testSuites = [] } = this.testReports;
      return testSuites.length > 0;
    },
  },
  async created() {
    await this.fetchSummary();
    const jobName = getParameterValues('job_name')[0] || '';
    if (jobName.length > 0) {
      // get the index from the job name
      const indexToSelect = this.getTestSuites.findIndex((test) => test.name === jobName);

      this.setSelectedSuiteIndex(indexToSelect);
      this.fetchTestSuite(indexToSelect);
    }
  },
  methods: {
    ...mapActions('testReports', [
      'fetchTestSuite',
      'fetchSummary',
      'setSelectedSuiteIndex',
      'removeSelectedSuiteIndex',
      'setPage',
    ]),
    summaryBackClick() {
      this.removeSelectedSuiteIndex();

      updateHistory({
        url: removeParams(['job_name']),
        title: document.title,
        replace: true,
      });

      // reset pagination to inital state
      this.setPage(1);
    },
    summaryTableRowClick(index) {
      this.setSelectedSuiteIndex(index);

      // Fetch the test suite when the user clicks to see more details
      this.fetchTestSuite(index);

      const urlParams = {
        job_name: this.getSelectedSuite.name,
      };

      updateHistory({
        url: setUrlParams(urlParams),
        title: document.title,
        replace: true,
      });
    },
    beforeEnterTransition() {
      document.documentElement.style.overflowX = 'hidden';
    },
    afterLeaveTransition() {
      document.documentElement.style.overflowX = '';
    },
  },
};
</script>

<template>
  <div v-if="isLoading">
    <gl-loading-icon size="lg" class="gl-mt-3" />
  </div>

  <div
    v-else-if="!isLoading && showTests"
    ref="container"
    class="gl-relative"
    data-testid="tests-detail"
  >
    <transition
      name="slide"
      @before-enter="beforeEnterTransition"
      @after-leave="afterLeaveTransition"
    >
      <div v-if="showSuite" key="detail" class="slide-enter-to-element gl-w-full">
        <test-summary :report="getSelectedSuite" show-back @on-back-click="summaryBackClick" />

        <test-suite-table />
      </div>

      <div v-else key="summary" class="slide-enter-from-element gl-w-full">
        <test-summary :report="testReports" />

        <test-summary-table @row-click="summaryTableRowClick" />
      </div>
    </transition>
  </div>

  <empty-state v-else />
</template>
