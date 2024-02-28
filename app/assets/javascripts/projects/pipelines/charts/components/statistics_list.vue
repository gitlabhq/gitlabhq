<script>
import { GlLink } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { s__, formatNumber } from '~/locale';

const defaultPrecision = 2;

export default {
  components: {
    GlLink,
    GlSingleStat,
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

      return [
        {
          label: s__('PipelineCharts|Total pipelines'),
          identifier: 'total-pipelines',
          value: formatNumber(this.counts.total),
        },
        {
          label: s__('PipelineCharts|Success ratio'),
          identifier: 'success-ratio',
          value: formatPercent(this.counts.successRatio, defaultPrecision),
        },
        {
          label: s__('PipelineCharts|Successful pipelines'),
          identifier: 'successful-pipelines',
          value: formatNumber(this.counts.success),
        },
        {
          label: s__('PipelineCharts|Failed pipelines'),
          identifier: 'failed-pipelines',
          value: formatNumber(this.counts.failed),
          link: this.failedPipelinesLink,
        },
      ];
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
  <div class="gl-display-flex gl-flex-wrap gl-gap-6 gl-mb-6">
    <div v-for="statistic in statistics" :key="statistic.label">
      <gl-single-stat
        :id="statistic.identifier"
        :value="`${statistic.value}`"
        :title="statistic.label"
        :unit="statistic.unit || ''"
        :should-animate="true"
        use-delimiters
      />
      <gl-link v-if="shouldDisplayLink(statistic)" class="gl-p-2" :href="statistic.link">{{
        s__('Pipeline|See details')
      }}</gl-link>
    </div>
  </div>
</template>
