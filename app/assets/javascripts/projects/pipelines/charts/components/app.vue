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
    shouldRenderLeadTimeCharts: {
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
      const chartsToShow = ['pipelines'];

      if (this.shouldRenderDeploymentFrequencyCharts) {
        chartsToShow.push('deployments');
      }

      if (this.shouldRenderLeadTimeCharts) {
        chartsToShow.push('lead-time');
      }

      return chartsToShow;
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
    <gl-tabs v-if="charts.length > 1" :value="selectedTab" @input="onTabChange">
      <gl-tab :title="__('Pipelines')">
        <pipeline-charts />
      </gl-tab>
      <gl-tab v-if="shouldRenderDeploymentFrequencyCharts" :title="__('Deployments')">
        <deployment-frequency-charts />
      </gl-tab>
      <gl-tab v-if="shouldRenderLeadTimeCharts" :title="__('Lead Time')">
        <lead-time-charts />
      </gl-tab>
    </gl-tabs>
    <pipeline-charts v-else />
  </div>
</template>
