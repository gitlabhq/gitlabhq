<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { isNumeric } from '~/lib/utils/number_utils';
import featureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  failedJobsTabName,
  jobsTabName,
  pipelineTabName,
  testReportTabName,
  manualVariablesTabName,
} from '../constants';

export default {
  i18n: {
    tabs: {
      failedJobsTitle: __('Failed Jobs'),
      jobsTitle: __('Jobs'),
      pipelineTitle: __('Pipeline'),
      testsTitle: __('Tests'),
      manualVariables: __('Manual Variables'),
    },
  },
  tabNames: {
    pipeline: pipelineTabName,
    jobs: jobsTabName,
    failures: failedJobsTabName,
    tests: testReportTabName,
    manualVariables: manualVariablesTabName,
  },
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin(), featureFlagMixin()],
  inject: [
    'defaultTabValue',
    'failedJobsCount',
    'totalJobCount',
    'testsCount',
    'manualVariablesCount',
  ],
  data() {
    return {
      activeTab: this.defaultTabValue,
      isDismissedNewTab: false,
    };
  },
  computed: {
    showFailedJobsTab() {
      return this.failedJobsCount > 0;
    },
    manualVariablesEnabled() {
      return (
        this.glFeatures.ciShowManualVariablesInPipeline && isNumeric(this.manualVariablesCount)
      );
    },
  },
  watch: {
    $route(to) {
      this.activeTab = to.name;
    },
  },
  methods: {
    isActive(tabName) {
      return tabName === this.activeTab;
    },
    navigateTo(tabName) {
      if (this.isActive(tabName)) return;

      this.$router.push({ name: tabName });
    },
    failedJobsTabClick() {
      this.track('click_tab', { label: TRACKING_CATEGORIES.failed });

      this.navigateTo(this.$options.tabNames.failures);
    },
    testsTabClick() {
      this.track('click_tab', { label: TRACKING_CATEGORIES.tests });

      this.navigateTo(this.$options.tabNames.tests);
    },
    manualVariablesTabClick() {
      this.track('click_tab', { label: TRACKING_CATEGORIES.manualVariables });
      this.isDismissedNewTab = true;

      this.navigateTo(this.$options.tabNames.manualVariables);
    },
  },
  MANUAL_VARIABLE_TAB_DISMISS_STORAGE_KEY: 'gl-ci-pipeline-detail-manual-variables-tab-dismissed',
};
</script>

<template>
  <gl-tabs>
    <gl-tab
      ref="pipelineTab"
      :title="$options.i18n.tabs.pipelineTitle"
      :active="isActive($options.tabNames.pipeline)"
      data-testid="pipeline-tab"
      lazy
      @click="navigateTo($options.tabNames.pipeline)"
    >
      <router-view />
    </gl-tab>
    <gl-tab
      :active="isActive($options.tabNames.jobs)"
      data-testid="jobs-tab"
      lazy
      @click="navigateTo($options.tabNames.jobs)"
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.jobsTitle }}</span>
        <gl-badge data-testid="builds-counter">{{ totalJobCount }}</gl-badge>
      </template>
      <router-view />
    </gl-tab>
    <gl-tab
      v-if="showFailedJobsTab"
      :title="$options.i18n.tabs.failedJobsTitle"
      :active="isActive($options.tabNames.failures)"
      data-testid="failed-jobs-tab"
      lazy
      @click="failedJobsTabClick"
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.failedJobsTitle }}</span>
        <gl-badge data-testid="failed-builds-counter">{{ failedJobsCount }}</gl-badge>
      </template>
      <router-view />
    </gl-tab>
    <gl-tab
      :active="isActive($options.tabNames.tests)"
      data-testid="tests-tab"
      lazy
      @click="testsTabClick"
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.testsTitle }}</span>
        <gl-badge data-testid="tests-counter">{{ testsCount }}</gl-badge>
      </template>
      <router-view />
    </gl-tab>
    <local-storage-sync
      v-if="manualVariablesEnabled"
      v-model="isDismissedNewTab"
      :storage-key="$options.MANUAL_VARIABLE_TAB_DISMISS_STORAGE_KEY"
    >
      <gl-tab
        :active="isActive($options.tabNames.manualVariables)"
        data-testid="manual-variables-tab"
        lazy
        @click="manualVariablesTabClick"
      >
        <template #title>
          <span class="gl-mr-2">{{ $options.i18n.tabs.manualVariables }}</span>
          <gl-badge data-testid="manual-variables-counter">{{ manualVariablesCount }}</gl-badge>
          <gl-badge
            v-if="!isDismissedNewTab"
            data-testid="manual-variables-new-badge"
            class="gl-ml-2"
            variant="info"
            >{{ __('new') }}</gl-badge
          >
        </template>
        <router-view />
      </gl-tab>
    </local-storage-sync>
    <slot></slot>
  </gl-tabs>
</template>
