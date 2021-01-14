<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import PipelineCharts from './pipeline_charts.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    PipelineCharts,
    DeploymentFrequencyCharts: () =>
      import('ee_component/projects/pipelines/charts/components/deployment_frequency_charts.vue'),
  },
  inject: {
    shouldRenderDeploymentFrequencyCharts: {
      type: Boolean,
      default: false,
    },
  },
  props: {
    counts: {
      type: Object,
      required: true,
    },
    timesChartData: {
      type: Object,
      required: true,
    },
    lastWeekChartData: {
      type: Object,
      required: true,
    },
    lastMonthChartData: {
      type: Object,
      required: true,
    },
    lastYearChartData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      // this loading flag gives the echarts library just enough time
      // to ensure all DOM nodes have been mounted.
      //
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1131
      loading: true,
    };
  },
  async mounted() {
    await this.$nextTick();
    this.loading = false;
  },
};
</script>
<template>
  <gl-tabs v-if="shouldRenderDeploymentFrequencyCharts">
    <gl-tab :title="__('Pipelines')">
      <pipeline-charts
        :counts="counts"
        :last-week="lastWeekChartData"
        :last-month="lastMonthChartData"
        :last-year="lastYearChartData"
        :times-chart="timesChartData"
        :loading="loading"
      />
    </gl-tab>
    <gl-tab :title="__('Deployments')">
      <deployment-frequency-charts />
    </gl-tab>
  </gl-tabs>
  <pipeline-charts
    v-else
    :counts="counts"
    :last-week="lastWeekChartData"
    :last-month="lastMonthChartData"
    :last-year="lastYearChartData"
    :times-chart="timesChartData"
  />
</template>
