<script>
import { GlButton, GlLink, GlProgressBar } from '@gitlab/ui';
import { __ } from '~/locale';
import { formatTime, secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'TestSummary',
  components: {
    GlButton,
    GlLink,
    GlProgressBar,
    Icon,
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
      return Number(((this.report.success_count / this.report.total_count) * 100 || 0).toFixed(2));
    },
    formattedDuration() {
      return formatTime(secondsToMilliseconds(this.report.total_time));
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
      <div class="col-12 d-flex prepend-top-8 align-items-center">
        <gl-button
          v-if="showBack"
          size="sm"
          class="append-right-default js-back-button"
          @click="onBackClick"
        >
          <icon name="angle-left" />
        </gl-button>

        <h4>{{ heading }}</h4>
      </div>
    </div>

    <div class="row mt-2">
      <div class="col-4 col-md">
        <span class="js-total-tests">{{
          sprintf(s__('TestReports|%{count} jobs'), { count: report.total_count })
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
