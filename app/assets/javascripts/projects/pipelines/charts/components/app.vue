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
      import('ee_component/dora/components/deployment_frequency_charts.vue'),
    LeadTimeCharts: () => import('ee_component/dora/components/lead_time_charts.vue'),
  },
  inject: {
    shouldRenderDoraCharts: {
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

      if (this.shouldRenderDoraCharts) {
        chartsToShow.push('deployment-frequency', 'lead-time');
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
      <template v-if="shouldRenderDoraCharts">
        <gl-tab :title="__('Deployment frequency')">
          <deployment-frequency-charts />
        </gl-tab>
        <gl-tab :title="__('Lead time')">
          <lead-time-charts />
        </gl-tab>
      </template>
    </gl-tabs>
    <pipeline-charts v-else />
  </div>
</template>
