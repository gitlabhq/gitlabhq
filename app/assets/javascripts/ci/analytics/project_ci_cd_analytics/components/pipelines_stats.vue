<script>
import { GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { formatBigInt } from '~/analytics/shared/utils';
import { s__ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  calculateRateDenominator,
  formatPipelineCountPercentage,
  formatPipelineDuration,
} from '../../utils';

export default {
  name: 'PipelinesStats',
  components: {
    GlSkeletonLoader,
    GlLink,
    GlSingleStat,
    HelpPopover,
  },
  props: {
    aggregate: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    failedPipelinesPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  failureRatePopover: {
    title: s__('PipelineCharts|How this is calculated?'),
    content: s__(
      "PipelineCharts|Rate = failed_pipelines / (success + failed). Canceled and skipped pipelines aren't included. Success rate is the inverse.",
    ),
  },
  computed: {
    failureRatioPath() {
      try {
        return BigInt(this.aggregate.failedCount) > 0n ? this.failedPipelinesPath : null;
      } catch {
        return null;
      }
    },
    stats() {
      const { count, successCount, failedCount, durationStatistics } = this.aggregate || {};
      const rateDenominator = calculateRateDenominator(successCount, failedCount, count);

      return [
        {
          label: s__('PipelineCharts|Total pipeline runs'),
          identifier: 'total-pipeline-runs',
          value: formatBigInt(count),
        },
        {
          label: s__('PipelineCharts|Median duration'),
          identifier: 'median-duration',
          value: formatPipelineDuration(durationStatistics?.p50),
        },
        {
          label: s__('PipelineCharts|Failure rate'),
          identifier: 'failure-ratio',
          value: formatPipelineCountPercentage(failedCount, rateDenominator),
          path: this.failureRatioPath,
          popover: this.$options.failureRatePopover,
        },
        {
          label: s__('PipelineCharts|Success rate'),
          identifier: 'success-ratio',
          value: formatPipelineCountPercentage(successCount, rateDenominator),
        },
      ];
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-flex-wrap gl-gap-6">
    <gl-skeleton-loader v-if="loading" :height="18">
      <rect width="45" height="18" rx="4" />
      <rect x="50" width="45" height="18" rx="4" />
      <rect x="100" width="45" height="18" rx="4" />
      <rect x="150" width="45" height="18" rx="4" />
    </gl-skeleton-loader>
    <template v-else>
      <div v-for="stat in stats" :key="stat.identifier">
        <div class="gl-flex gl-items-start">
          <gl-single-stat
            :id="stat.identifier"
            :value="stat.value"
            :title="stat.label"
            :aria-busy="loading"
            should-animate
          />
          <help-popover
            v-if="stat.popover"
            :options="stat.popover"
            icon="information-o"
            trigger-class="gl-text-subtle"
            :data-testid="`${stat.identifier}-help-popover`"
          />
        </div>
        <gl-link
          v-if="stat.path"
          class="gl-p-2"
          :href="stat.path"
          data-event-tracking="click_view_all_link_in_pipeline_analytics"
          >{{ s__('Pipeline|View all') }}</gl-link
        >
      </div>
    </template>
  </div>
</template>
