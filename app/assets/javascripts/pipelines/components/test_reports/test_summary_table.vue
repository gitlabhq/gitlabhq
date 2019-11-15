<script>
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';
import store from '~/pipelines/stores/test_reports';

export default {
  name: 'TestsSummaryTable',
  store,
  props: {
    heading: {
      type: String,
      required: false,
      default: s__('TestReports|Test suites'),
    },
  },
  computed: {
    ...mapGetters(['getTestSuites']),
    hasSuites() {
      return this.getTestSuites.length > 0;
    },
  },
  methods: {
    tableRowClick(suite) {
      this.$emit('row-click', suite);
    },
  },
};
</script>

<template>
  <div>
    <div class="row prepend-top-default">
      <div class="col-12">
        <h4>{{ heading }}</h4>
      </div>
    </div>

    <div v-if="hasSuites" class="test-reports-table js-test-suites-table">
      <div role="row" class="gl-responsive-table-row table-row-header font-weight-bold">
        <div role="rowheader" class="table-section section-25 pl-3">
          {{ __('Suite') }}
        </div>
        <div role="rowheader" class="table-section section-25">
          {{ __('Duration') }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Failed') }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Errors'), }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Skipped'), }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Passed'), }}
        </div>
        <div role="rowheader" class="table-section section-10 pr-3 text-right">
          {{ __('Total') }}
        </div>
      </div>

      <div
        v-for="(testSuite, index) in getTestSuites"
        :key="index"
        role="row"
        class="gl-responsive-table-row gl-responsive-table-row-clickable test-reports-summary-row rounded cursor-pointer js-suite-row"
        @click="tableRowClick(testSuite)"
      >
        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Suite') }}
          </div>
          <div class="table-mobile-content underline cgray pl-3">
            {{ testSuite.name }}
          </div>
        </div>

        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Duration') }}
          </div>
          <div class="table-mobile-content text-md-left">
            {{ testSuite.formattedTime }}
          </div>
        </div>

        <div class="table-section section-10 text-center">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Failed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.failed_count }}</div>
        </div>

        <div class="table-section section-10 text-center">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Errors') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.error_count }}</div>
        </div>

        <div class="table-section section-10 text-center">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Skipped') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.skipped_count }}</div>
        </div>

        <div class="table-section section-10 text-center">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Passed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.success_count }}</div>
        </div>

        <div class="table-section section-10 text-right pr-md-3">
          <div role="rowheader" class="table-mobile-header font-weight-bold">
            {{ __('Total') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.total_count }}</div>
        </div>
      </div>
    </div>

    <div v-else>
      <p class="js-no-tests-suites">{{ s__('TestReports|There are no test suites to show.') }}</p>
    </div>
  </div>
</template>
