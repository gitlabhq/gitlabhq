<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import MigrationAlert from 'ee_component/analytics/dora/components/migration_alert.vue';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PipelinesDashboard from './pipelines_dashboard.vue';
import PipelinesDashboardClickhouse from './pipelines_dashboard_clickhouse.vue';

const URL_PARAM_KEY = 'chart';

export default {
  name: 'ProjectCiCdAnalyticsApp',
  components: {
    GlTabs,
    GlTab,
    MigrationAlert,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  inject: {
    projectPath: {
      type: String,
      default: '',
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
    const isClickHouseAvailable = this.clickHouseEnabledForAnalytics;

    const tabs = [
      {
        key: 'pipelines',
        event: 'p_analytics_ci_cd_pipelines',
        title: __('Pipelines'),
        componentIs: isClickHouseAvailable ? PipelinesDashboardClickhouse : PipelinesDashboard,
        lazy: true,
      },
    ];

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
    <migration-alert :namespace-path="projectPath" is-project />

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
