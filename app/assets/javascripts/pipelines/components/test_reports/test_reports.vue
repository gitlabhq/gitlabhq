<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import TestSuiteTable from './test_suite_table.vue';
import TestSummary from './test_summary.vue';
import TestSummaryTable from './test_summary_table.vue';

export default {
  name: 'TestReports',
  components: {
    GlLoadingIcon,
    TestSuiteTable,
    TestSummary,
    TestSummaryTable,
  },
  computed: {
    ...mapState(['hasFullReport', 'isLoading', 'selectedSuiteIndex', 'testReports']),
    ...mapGetters(['getSelectedSuite']),
    showSuite() {
      return this.selectedSuiteIndex !== null;
    },
    showTests() {
      const { test_suites: testSuites = [] } = this.testReports;
      return testSuites.length > 0;
    },
  },
  created() {
    this.fetchSummary();
  },
  methods: {
    ...mapActions([
      'fetchTestSuite',
      'fetchSummary',
      'setSelectedSuiteIndex',
      'removeSelectedSuiteIndex',
    ]),
    summaryBackClick() {
      this.removeSelectedSuiteIndex();
    },
    summaryTableRowClick(index) {
      this.setSelectedSuiteIndex(index);

      // Fetch the test suite when the user clicks to see more details
      this.fetchTestSuite(index);
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
    <gl-loading-icon size="lg" class="gl-mt-3 js-loading-spinner" />
  </div>

  <div
    v-else-if="!isLoading && showTests"
    ref="container"
    class="tests-detail position-relative js-tests-detail"
  >
    <transition
      name="slide"
      @before-enter="beforeEnterTransition"
      @after-leave="afterLeaveTransition"
    >
      <div v-if="showSuite" key="detail" class="w-100 position-absolute slide-enter-to-element">
        <test-summary :report="getSelectedSuite" show-back @on-back-click="summaryBackClick" />

        <test-suite-table />
      </div>

      <div v-else key="summary" class="w-100 position-absolute slide-enter-from-element">
        <test-summary :report="testReports" />

        <test-summary-table @row-click="summaryTableRowClick" />
      </div>
    </transition>
  </div>

  <div v-else>
    <div class="row gl-mt-3">
      <div class="col-12">
        <p class="js-no-tests-to-show">{{ s__('TestReports|There are no tests to show.') }}</p>
      </div>
    </div>
  </div>
</template>
