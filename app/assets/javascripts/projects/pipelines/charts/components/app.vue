<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PipelinesDashboard from './pipelines_dashboard.vue';
import PipelinesDashboardClickhouse from './pipelines_dashboard_clickhouse.vue';

const URL_PARAM_KEY = 'chart';

export default {
  components: {
    GlTabs,
    GlTab,
  },
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
    clickHouseEnabledForAnalytics: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    const isClickHouseAvailable =
      this.clickHouseEnabledForAnalytics && this.glFeatures?.ciImprovedProjectPipelineAnalytics;

    const tabs = [
      {
        key: 'pipelines',
        event: 'p_analytics_ci_cd_pipelines',
        title: __('Pipelines'),
        componentIs: isClickHouseAvailable ? PipelinesDashboardClickhouse : PipelinesDashboard,
        lazy: true,
      },
    ];

    if (this.shouldRenderDoraCharts) {
      tabs.push(
        {
          key: 'deployment-frequency',
          event: 'p_analytics_ci_cd_deployment_frequency',
          title: __('Deployment frequency'),
          componentIs: () => import('ee_component/dora/components/deployment_frequency_charts.vue'),
          lazy: true,
        },
        {
          key: 'lead-time',
          event: 'p_analytics_ci_cd_lead_time',
          title: __('Lead time'),
          componentIs: () => import('ee_component/dora/components/lead_time_charts.vue'),
          lazy: true,
        },
        {
          key: 'time-to-restore-service',
          event: 'visit_ci_cd_time_to_restore_service_tab',
          title: s__('DORA4Metrics|Time to restore service'),
          componentIs: () =>
            import('ee_component/dora/components/time_to_restore_service_charts.vue'),
          lazy: true,
        },
        {
          key: 'change-failure-rate',
          event: 'visit_ci_cd_failure_rate_tab',
          title: s__('DORA4Metrics|Change failure rate'),
          componentIs: () => import('ee_component/dora/components/change_failure_rate_charts.vue'),
          lazy: true,
        },
      );
    }

    if (this.shouldRenderQualitySummary) {
      tabs.push({
        key: 'project-quality',
        title: s__('QualitySummary|Project quality'),
        componentIs: () => import('ee_component/project_quality_summary/app.vue'),
        lazy: true,
      });
    }

    return {
      activeTabIndex: 0,
      tabs,
    };
  },
  created() {
    this.syncActiveTab();
    window.addEventListener('popstate', this.syncActiveTab);
  },
  methods: {
    syncActiveTab() {
      const paramValue = getParameterValues(URL_PARAM_KEY)?.[0];
      const selectedIndex = this.tabs.map((tab) => tab.key).indexOf(paramValue);
      this.activeTabIndex = selectedIndex >= 0 ? selectedIndex : 0;
    },
    onTabInput(index) {
      if (index !== this.activeTabIndex) {
        const tab = this.tabs[index];
        const path = mergeUrlParams({ [URL_PARAM_KEY]: tab.key }, window.location.pathname);

        this.activeTabIndex = index;
        tab.lazy = false; // mount the tab permanently after it is shown
        updateHistory({ url: path, title: window.title });
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs v-if="tabs.length > 1" :value="activeTabIndex" @input="onTabInput">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.key"
        :title="tab.title"
        :lazy="tab.lazy"
        @click="tab.event && trackEvent(tab.event)"
      >
        <component :is="tab.componentIs" />
      </gl-tab>
    </gl-tabs>
    <component :is="tabs[0].componentIs" v-else />
  </div>
</template>
