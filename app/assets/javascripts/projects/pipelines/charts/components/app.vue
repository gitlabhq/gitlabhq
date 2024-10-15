<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PipelineCharts from './pipeline_charts.vue';
import PipelineChartsNew from './pipeline_charts_new.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    PipelineCharts,
    PipelineChartsNew,
    DeploymentFrequencyCharts: () =>
      import('ee_component/dora/components/deployment_frequency_charts.vue'),
    LeadTimeCharts: () => import('ee_component/dora/components/lead_time_charts.vue'),
    TimeToRestoreServiceCharts: () =>
      import('ee_component/dora/components/time_to_restore_service_charts.vue'),
    ChangeFailureRateCharts: () =>
      import('ee_component/dora/components/change_failure_rate_charts.vue'),
    ProjectQualitySummary: () => import('ee_component/project_quality_summary/app.vue'),
  },
  piplelinesTabEvent: 'p_analytics_ci_cd_pipelines',
  deploymentFrequencyTabEvent: 'p_analytics_ci_cd_deployment_frequency',
  leadTimeTabEvent: 'p_analytics_ci_cd_lead_time',
  timeToRestoreServiceTabEvent: 'visit_ci_cd_time_to_restore_service_tab',
  changeFailureRateTabEvent: 'visit_ci_cd_failure_rate_tab',
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  inject: {
    shouldRenderDoraCharts: {
      type: Boolean,
      default: false,
    },
    shouldRenderQualitySummary: {
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
        chartsToShow.push(
          'deployment-frequency',
          'lead-time',
          'time-to-restore-service',
          'change-failure-rate',
        );
      }

      if (this.shouldRenderQualitySummary) {
        chartsToShow.push('project-quality');
      }

      return chartsToShow;
    },
    pipelineChartsComponent() {
      if (this.glFeatures?.ciImprovedProjectPipelineAnalytics) {
        return PipelineChartsNew;
      }
      return PipelineCharts;
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
      <gl-tab
        :title="__('Pipelines')"
        data-testid="pipelines-tab"
        @click="trackEvent($options.piplelinesTabEvent)"
      >
        <component :is="pipelineChartsComponent" />
      </gl-tab>
      <template v-if="shouldRenderDoraCharts">
        <gl-tab
          :title="__('Deployment frequency')"
          data-testid="deployment-frequency-tab"
          @click="trackEvent($options.deploymentFrequencyTabEvent)"
        >
          <deployment-frequency-charts />
        </gl-tab>
        <gl-tab
          :title="__('Lead time')"
          data-testid="lead-time-tab"
          @click="trackEvent($options.leadTimeTabEvent)"
        >
          <lead-time-charts />
        </gl-tab>
        <gl-tab
          :title="s__('DORA4Metrics|Time to restore service')"
          data-testid="time-to-restore-service-tab"
          @click="trackEvent($options.timeToRestoreServiceTabEvent)"
        >
          <time-to-restore-service-charts />
        </gl-tab>
        <gl-tab
          :title="s__('DORA4Metrics|Change failure rate')"
          data-testid="change-failure-rate-tab"
          @click="trackEvent($options.changeFailureRateTabEvent)"
        >
          <change-failure-rate-charts />
        </gl-tab>
      </template>
      <gl-tab v-if="shouldRenderQualitySummary" :title="s__('QualitySummary|Project quality')">
        <project-quality-summary />
      </gl-tab>
    </gl-tabs>
    <component :is="pipelineChartsComponent" v-else />
  </div>
</template>
