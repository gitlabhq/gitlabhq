<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import API from '~/api';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import PipelineCharts from './pipeline_charts.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    PipelineCharts,
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
  timeToRestoreServiceTabEvent: 'p_analytics_ci_cd_time_to_restore_service',
  changeFailureRateTabEvent: 'p_analytics_ci_cd_change_failure_rate',
  mixins: [InternalEvents.mixin()],
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
    trackTabClick(event, trackWithInternalEvents = false) {
      if (trackWithInternalEvents) {
        this.trackEvent(event);
        return;
      }
      API.trackRedisHllUserEvent(event);
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
        @click="trackTabClick($options.piplelinesTabEvent, true)"
      >
        <pipeline-charts />
      </gl-tab>
      <template v-if="shouldRenderDoraCharts">
        <gl-tab
          :title="__('Deployment frequency')"
          data-testid="deployment-frequency-tab"
          @click="trackTabClick($options.deploymentFrequencyTabEvent, true)"
        >
          <deployment-frequency-charts />
        </gl-tab>
        <gl-tab
          :title="__('Lead time')"
          data-testid="lead-time-tab"
          @click="trackTabClick($options.leadTimeTabEvent, true)"
        >
          <lead-time-charts />
        </gl-tab>
        <gl-tab
          :title="s__('DORA4Metrics|Time to restore service')"
          data-testid="time-to-restore-service-tab"
          @click="trackTabClick($options.timeToRestoreServiceTabEvent)"
        >
          <time-to-restore-service-charts />
        </gl-tab>
        <gl-tab
          :title="s__('DORA4Metrics|Change failure rate')"
          data-testid="change-failure-rate-tab"
          @click="trackTabClick($options.changeFailureRateTabEvent)"
        >
          <change-failure-rate-charts />
        </gl-tab>
      </template>
      <gl-tab v-if="shouldRenderQualitySummary" :title="s__('QualitySummary|Project quality')">
        <project-quality-summary />
      </gl-tab>
    </gl-tabs>
    <pipeline-charts v-else />
  </div>
</template>
