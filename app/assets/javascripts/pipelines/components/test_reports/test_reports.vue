<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import TestSuiteTable from './test_suite_table.vue';
import TestSummary from './test_summary.vue';
import TestSummaryTable from './test_summary_table.vue';
import store from '~/pipelines/stores/test_reports';

export default {
  name: 'TestReports',
  components: {
    GlLoadingIcon,
    TestSuiteTable,
    TestSummary,
    TestSummaryTable,
  },
  store,
  computed: {
    ...mapState(['isLoading', 'selectedSuite', 'testReports']),
    showSuite() {
      return this.selectedSuite.total_count > 0;
    },
    showTests() {
      return this.testReports.total_count > 0;
    },
  },
  methods: {
    ...mapActions(['setSelectedSuite', 'removeSelectedSuite']),
    summaryBackClick() {
      this.removeSelectedSuite();
    },
    summaryTableRowClick(suite) {
      this.setSelectedSuite(suite);
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
    <gl-loading-icon size="lg" class="prepend-top-default js-loading-spinner" />
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
        <test-summary :report="selectedSuite" show-back @on-back-click="summaryBackClick" />

        <test-suite-table />
      </div>

      <div v-else key="summary" class="w-100 position-absolute slide-enter-from-element">
        <test-summary :report="testReports" />

        <test-summary-table @row-click="summaryTableRowClick" />
      </div>
    </transition>
  </div>

  <div v-else>
    <div class="row prepend-top-default">
      <div class="col-12">
        <p class="js-no-tests-to-show">{{ s__('TestReports|There are no tests to show.') }}</p>
      </div>
    </div>
  </div>
</template>
