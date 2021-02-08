<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import PipelineCharts from './pipeline_charts.vue';

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
    return {
      selectedTab: 0,
    };
  },
  created() {
    this.selectTab();
    window.addEventListener('popstate', this.selectTab);
  },
  methods: {
    selectTab() {
      const [chart] = getParameterValues('chart') || charts;
      const tab = charts.indexOf(chart);
      this.selectedTab = tab >= 0 ? tab : 0;
    },
    onTabChange(index) {
      if (index !== this.selectedTab) {
        this.selectedTab = index;
        const path = mergeUrlParams({ chart: charts[index] }, window.location.pathname);
        updateHistory({ url: path, title: window.title });
      }
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
