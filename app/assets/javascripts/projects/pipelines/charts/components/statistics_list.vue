<script>
import { GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { formatTimeSpent } from '~/lib/utils/datetime_utility';
import { s__, formatNumber } from '~/locale';

const defaultPrecision = 0;

export default {
  components: {
    GlLink,
    GlSingleStat,
    GlSkeletonLoader,
  },
  inject: {
    failedPipelinesLink: {
      default: '',
    },
  },
  props: {
    counts: {
      type: Object,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    statistics() {
      const formatPercent = getFormatter(SUPPORTED_FORMATS.percentHundred);

      const statistics = [
        {
          label: s__('PipelineCharts|Total pipeline runs'),
          identifier: 'total-pipeline-runs',
          value: formatNumber(this.counts.total),
        },
        {
          label: s__('PipelineCharts|Failure rate'),
          identifier: 'failure-ratio',
          value: formatPercent(this.counts.failureRatio, defaultPrecision),
          link: this.failedPipelinesLink,
        },
        {
          label: s__('PipelineCharts|Success rate'),
          identifier: 'success-ratio',
          value: formatPercent(this.counts.successRatio, defaultPrecision),
        },
      ];

      if (this.counts.medianDuration) {
        statistics.splice(1, 0, {
          label: s__('PipelineCharts|Median duration'),
          identifier: 'median-duration',
          value: formatTimeSpent(this.counts.medianDuration),
        });
      }

      return statistics;
    },
  },
  methods: {
    shouldDisplayLink(statistic) {
      return statistic.link && statistic.value !== 0;
    },
  },
};
</script>
<template>
  <div class="gl-mb-6 gl-flex gl-flex-wrap gl-gap-6">
    <gl-skeleton-loader v-if="loading" :height="30">
      <rect width="45" height="30" rx="4" />
      <rect x="50" width="45" height="30" rx="4" />
      <rect x="100" width="45" height="30" rx="4" />
      <rect x="150" width="45" height="30" rx="4" />
    </gl-skeleton-loader>
    <template v-else>
      <div v-for="statistic in statistics" :key="statistic.label">
        <gl-single-stat
          :id="statistic.identifier"
          :value="`${statistic.value}`"
          :title="statistic.label"
          :unit="statistic.unit || ''"
          :should-animate="true"
          use-delimiters
        />
        <gl-link
          v-if="shouldDisplayLink(statistic)"
          class="gl-p-2"
          :href="statistic.link"
          data-event-tracking="click_view_all_link_in_pipeline_analytics"
          >{{ s__('Pipeline|View all') }}</gl-link
        >
      </div>
    </template>
  </div>
</template>
