<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import PipelineCharts from './pipeline_charts.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    PipelineCharts,
    DeploymentFrequencyCharts: () =>
      import('ee_component/projects/pipelines/charts/components/deployment_frequency_charts.vue'),
    LeadTimeCharts: () =>
      import('ee_component/projects/pipelines/charts/components/lead_time_charts.vue'),
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
  computed: {
    charts() {
      if (this.shouldRenderDeploymentFrequencyCharts) {
        return ['pipelines', 'deployments', 'lead-time'];
      }

      return ['pipelines', 'lead-time'];
    },
  },
  created() {
    this.selectTab();
    window.addEventListener('popstate', this.selectTab);
  },
  methods: {
    selectTab() {
      const [chart] = getParameterValues('chart') || this.charts;
      const tab = this.charts.indexOf(chart);
      this.selectedTab = tab >= 0 ? tab : 0;
    },
    onTabChange(index) {
      if (index !== this.selectedTab) {
        this.selectedTab = index;
        const path = mergeUrlParams({ chart: this.charts[index] }, window.location.pathname);
        updateHistory({ url: path, title: window.title });
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs :value="selectedTab" @input="onTabChange">
      <gl-tab :title="__('Pipelines')">
        <pipeline-charts />
      </gl-tab>
      <gl-tab v-if="shouldRenderDeploymentFrequencyCharts" :title="__('Deployments')">
        <deployment-frequency-charts />
      </gl-tab>
      <gl-tab :title="__('Lead Time')">
        <lead-time-charts />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
