<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'TestsSummaryTable',
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: s__('TestReports|Jobs'),
    },
  },
  computed: {
    ...mapGetters('testReports', ['getTestSuites']),
    hasSuites() {
      return this.getTestSuites.length > 0;
    },
  },
  methods: {
    tableRowClick(index) {
      this.$emit('row-click', index);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mt-5">
      <h4>{{ heading }}</h4>
    </div>

    <div v-if="hasSuites" class="js-test-suites-table">
      <div role="row" class="gl-responsive-table-row table-row-header gl-font-bold">
        <div role="rowheader" class="table-section section-25 gl-pl-5">
          {{ __('Job') }}
        </div>
        <div role="rowheader" class="table-section section-25">
          {{ __('Duration') }}
        </div>
        <div role="rowheader" class="table-section section-10 gl-text-center">
          {{ __('Failed') }}
        </div>
        <div role="rowheader" class="table-section section-10 gl-text-center">
          {{ __('Errors') }}
        </div>
        <div role="rowheader" class="table-section section-10 gl-text-center">
          {{ __('Skipped') }}
        </div>
        <div role="rowheader" class="table-section section-10 gl-text-center">
          {{ __('Passed') }}
        </div>
        <div role="rowheader" class="table-section section-10 gl-pr-5 gl-text-right">
          {{ __('Total') }}
        </div>
      </div>

      <div
        v-for="(testSuite, index) in getTestSuites"
        :key="index"
        role="row"
        class="gl-responsive-table-row js-suite-row gl-rounded-base"
        :class="{
          'gl-responsive-table-row-clickable gl-cursor-pointer': !testSuite.suite_error,
        }"
        @click="tableRowClick(index)"
      >
        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Suite') }}
          </div>
          <div class="table-mobile-content underline gl-pl-5 gl-text-default">
            {{ testSuite.name }}
            <gl-icon
              v-if="testSuite.suite_error"
              ref="suiteErrorIcon"
              v-gl-tooltip
              name="error"
              :title="testSuite.suite_error"
              class="vertical-align-middle"
            />
          </div>
        </div>

        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Duration') }}
          </div>
          <div class="table-mobile-content gl-text-left">
            {{ testSuite.formattedTime }}
          </div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Failed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.failed_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Errors') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.error_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Skipped') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.skipped_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Passed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.success_count }}</div>
        </div>

        <div class="table-section section-10 pr-md-3 gl-text-right">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
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
