<script>
import { GlButton, GlProgressBar } from '@gitlab/ui';
import { __ } from '~/locale';
import { formattedTime } from '../../stores/test_reports/utils';

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
    <div class="row">
      <div class="col-12 d-flex gl-mt-3 align-items-center">
        <gl-button
          v-if="showBack"
          size="small"
          class="gl-mr-3 js-back-button"
          icon="angle-left"
          :aria-label="__('Go back')"
          @click="onBackClick"
        />

        <h4>{{ heading }}</h4>
      </div>
    </div>

    <div class="row mt-2">
      <div class="col-4 col-md">
        <span class="js-total-tests">{{
          sprintf(s__('TestReports|%{count} tests'), { count: report.total_count })
        }}</span>
      </div>

      <div class="col-4 col-md text-center text-md-center">
        <span class="js-failed-tests">{{
          sprintf(s__('TestReports|%{count} failures'), { count: report.failed_count })
        }}</span>
      </div>

      <div class="col-4 col-md text-right text-md-center">
        <span class="js-errored-tests">{{
          sprintf(s__('TestReports|%{count} errors'), { count: report.error_count })
        }}</span>
      </div>

      <div class="col-6 mt-3 col-md mt-md-0 text-md-center">
        <span class="js-success-rate">{{
          sprintf(s__('TestReports|%{rate}%{sign} success rate'), {
            rate: successPercentage,
            sign: '%',
          })
        }}</span>
      </div>

      <div class="col-6 mt-3 col-md mt-md-0 text-right">
        <span class="js-duration">{{ formattedDuration }}</span>
      </div>
    </div>

    <div class="row mt-3">
      <div class="col-12">
        <gl-progress-bar :value="successPercentage" :variant="progressBarVariant" height="10px" />
      </div>
    </div>
  </div>
</template>
