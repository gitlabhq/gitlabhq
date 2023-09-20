<script>
import { GlButton, GlProgressBar } from '@gitlab/ui';
import { __ } from '~/locale';
import { formattedTime } from '../stores/test_reports/utils';

export default {
  name: 'TestSummary',
  components: {
    GlButton,
    GlProgressBar,
  },
  props: {
    report: {
      type: Object,
      required: true,
    },
    showBack: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    heading() {
      return this.report.name || __('Summary');
    },
    successPercentage() {
      // Returns a full number when the decimals equal .00.
      // Otherwise returns a float to two decimal points
      // Do not include skipped tests as part of the total when doing success calculations.

      const totalCompletedCount = this.report.total_count - this.report.skipped_count;

      if (totalCompletedCount > 0) {
        return Number(((this.report.success_count / totalCompletedCount) * 100 || 0).toFixed(2));
      }
      return 0;
    },
    formattedDuration() {
      return formattedTime(this.report.total_time);
    },
    progressBarVariant() {
      if (this.successPercentage < 33) {
        return 'danger';
      }

      if (this.successPercentage >= 33 && this.successPercentage < 66) {
        return 'warning';
      }

      if (this.successPercentage >= 66 && this.successPercentage < 90) {
        return 'primary';
      }

      return 'success';
    },
  },
  methods: {
    onBackClick() {
      this.$emit('on-back-click');
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-w-full gl-display-flex gl-mt-3 gl-align-items-center">
      <gl-button
        v-if="showBack"
        size="small"
        class="gl-mr-3 js-back-button"
        icon="chevron-lg-left"
        :aria-label="__('Go back')"
        @click="onBackClick"
      />

      <h4>{{ heading }}</h4>
    </div>

    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-w-full gl-mt-3"
    >
      <div class="gl-display-flex gl-justify-content-space-between gl-flex-basis-half">
        <span class="js-total-tests gl-flex-grow-1">{{
          sprintf(s__('TestReports|%{count} tests'), { count: report.total_count })
        }}</span>

        <span class="js-failed-tests gl-flex-grow-1">{{
          sprintf(s__('TestReports|%{count} failures'), { count: report.failed_count })
        }}</span>

        <span class="js-errored-tests">{{
          sprintf(s__('TestReports|%{count} errors'), { count: report.error_count })
        }}</span>
      </div>
      <div class="gl-display-flex gl-justify-content-space-between gl-flex-grow-1">
        <div class="gl-display-none gl-md-display-block gl-flex-grow-1"></div>
        <span class="js-success-rate gl-flex-grow-1">{{
          sprintf(s__('TestReports|%{rate}%{sign} success rate'), {
            rate: successPercentage,
            sign: '%',
          })
        }}</span>

        <span class="js-duration">{{ formattedDuration }}</span>
      </div>
    </div>

    <gl-progress-bar
      class="gl-mt-5"
      :value="successPercentage"
      :variant="progressBarVariant"
      height="10px"
    />
  </div>
</template>
