<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import PipelineCharts from './pipeline_charts.vue';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';

const charts = ['pipelines', 'deployments'];

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
  data() {
    const [chart] = getParameterValues('chart') || charts;
    const tab = charts.indexOf(chart);
    return {
      chart,
      selectedTab: tab >= 0 ? tab : 0,
    };
  },
  methods: {
    onTabChange(index) {
      this.selectedTab = index;
      const path = mergeUrlParams({ chart: charts[index] }, window.location.pathname);
      updateHistory({ url: path });
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs v-if="shouldRenderDeploymentFrequencyCharts" :value="selectedTab" @input="onTabChange">
      <gl-tab :title="__('Pipelines')">
        <pipeline-charts />
      </gl-tab>
      <gl-tab :title="__('Deployments')">
        <deployment-frequency-charts />
      </gl-tab>
    </gl-tabs>
    <pipeline-charts v-else />
  </div>
</template>
