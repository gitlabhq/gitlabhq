<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { CREATE_EXPERIMENT_HELP_PATH } from '~/ml/experiment_tracking/routes/experiments/index/constants';

export default {
  name: 'PerformanceGraph',
  components: { GlLineChart, GlEmptyState },
  props: {
    candidates: {
      type: Array,
      required: true,
    },
    metricNames: {
      type: Array,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      tooltipTitle: null,
      tooltipValue: null,
    };
  },
  i18n: {
    xAxisLabel: s__('ExperimentTracking|Run'),
    yAxisLabel: s__('ExperimentTracking|Metric value'),
    createNewCandidateLabel: s__('ExperimentTracking|Create run using MLflow'),
    emptyStateLabel: s__('ExperimentTracking|No runs with logged metrics'),
    emptyStateDescriptionLabel: s__(
      'ExperimentTracking|Performance graph will be shown when runs with logged metrics are available',
    ),
  },
  computed: {
    graphData() {
      return this.metricNames.map((metric) => {
        return {
          name: metric,
          data: [...this.candidates]
            .sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
            .filter((candidate) => candidate[metric] !== undefined && candidate[metric] !== null)
            .map((candidate, index) => ({
              value: [index + 1, parseFloat(candidate[metric])],
              name: candidate.name,
            })),
        };
      });
    },
    graphOptions() {
      return {
        animation: true,
        xAxis: { name: this.$options.i18n.xAxisLabel, type: 'category' },
        yAxis: { name: this.$options.i18n.yAxisLabel, type: 'value' },
        dataZoom: [
          {
            type: 'slider',
            startValue: 0,
            minSpan: 1,
            minSpanValue: 1,
          },
        ],
        toolbox: { show: true },
      };
    },
    showGraph() {
      return this.candidates.length > 0 && this.metricNames.length > 0;
    },
  },
  constants: {
    CREATE_EXPERIMENT_HELP_PATH,
  },
  methods: {
    formatTooltipText(params) {
      this.tooltipTitle = params.seriesData[0].name;
      this.tooltipValue = params.seriesData.map((item) => ({
        title: item.seriesName,
        value: item.data.value[1],
      }));
    },
  },
};
</script>

<template>
  <gl-line-chart
    v-if="showGraph"
    :data="graphData"
    :option="graphOptions"
    show-legend
    :include-legend-avg-max="false"
    :format-tooltip-text="formatTooltipText"
    :height="null"
  >
    <template #tooltip-title> {{ tooltipTitle }} </template>
    <template #tooltip-content>
      <div class="gl-flex gl-flex-col">
        <div v-for="metric in tooltipValue" :key="metric.title" class="gl-flex gl-justify-between">
          <div class="gl-mr-5">{{ metric.title }}</div>
          <div class="gl-font-bold" data-testid="tooltip-value">{{ metric.value }}</div>
        </div>
      </div>
    </template>
  </gl-line-chart>
  <gl-empty-state
    v-else
    :title="$options.i18n.emptyStateLabel"
    :secondary-button-text="$options.i18n.createNewCandidateLabel"
    :secondary-button-link="$options.constants.CREATE_EXPERIMENT_HELP_PATH"
    :svg-path="emptyStateSvgPath"
    :svg-height="null"
    :description="$options.i18n.emptyStateDescriptionLabel"
    class="gl-py-8"
  />
</template>
