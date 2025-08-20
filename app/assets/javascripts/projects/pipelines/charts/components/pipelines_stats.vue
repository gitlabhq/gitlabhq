<script>
import { GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { s__ } from '~/locale';
import {
  formatPipelineCount,
  formatPipelineCountPercentage,
  formatPipelineDuration,
} from '../format_utils';

export default {
  name: 'PipelinesStats',
  components: {
    GlSkeletonLoader,
    GlLink,
    GlSingleStat,
  },
  inject: {
    failedPipelinesLink: {
      default: null,
    },
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
  },
  computed: {
    failureRatioLink() {
      try {
        return BigInt(this.aggregate.failedCount) > 0n ? this.failedPipelinesLink : null;
      } catch {
        return null;
      }
    },
    stats() {
      const { count, successCount, failedCount, durationStatistics } = this.aggregate || {};

      return [
        {
          label: s__('PipelineCharts|Total pipeline runs'),
          identifier: 'total-pipeline-runs',
          value: formatPipelineCount(count),
        },
        {
          label: s__('PipelineCharts|Median duration'),
          identifier: 'median-duration',
          value: formatPipelineDuration(durationStatistics?.p50),
        },
        {
          label: s__('PipelineCharts|Failure rate'),
          identifier: 'failure-ratio',
          value: formatPipelineCountPercentage(failedCount, count),
          link: this.failureRatioLink,
        },
        {
          label: s__('PipelineCharts|Success rate'),
          identifier: 'success-ratio',
          value: formatPipelineCountPercentage(successCount, count),
        },
      ];
    },
  },
};
</script>
<template>
  <div class="gl-mb-6 gl-flex gl-flex-wrap gl-gap-6">
    <gl-skeleton-loader v-if="loading" :height="18">
      <rect width="45" height="18" rx="4" />
      <rect x="50" width="45" height="18" rx="4" />
      <rect x="100" width="45" height="18" rx="4" />
      <rect x="150" width="45" height="18" rx="4" />
    </gl-skeleton-loader>
    <template v-else>
      <div v-for="stat in stats" :key="stat.identifier">
        <gl-single-stat
          :id="stat.identifier"
          :value="stat.value"
          :title="stat.label"
          :aria-busy="loading"
          should-animate
        />
        <gl-link
          v-if="stat.link"
          class="gl-p-2"
          :href="stat.link"
          data-event-tracking="click_view_all_link_in_pipeline_analytics"
          >{{ s__('Pipeline|View all') }}</gl-link
        >
      </div>
    </template>
  </div>
</template>
