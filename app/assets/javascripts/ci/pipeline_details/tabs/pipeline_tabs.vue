<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import {
  failedJobsTabName,
  jobsTabName,
  needsTabName,
  pipelineTabName,
  testReportTabName,
} from '../constants';

export default {
  i18n: {
    tabs: {
      failedJobsTitle: __('Failed Jobs'),
      jobsTitle: __('Jobs'),
      needsTitle: __('Needs'),
      pipelineTitle: __('Pipeline'),
      testsTitle: __('Tests'),
    },
  },
  tabNames: {
    pipeline: pipelineTabName,
    needs: needsTabName,
    jobs: jobsTabName,
    failures: failedJobsTabName,
    tests: testReportTabName,
  },
  components: {
    GlBadge,
    GlTab,
    GlTabs,
  },
  mixins: [Tracking.mixin()],
  inject: ['defaultTabValue', 'failedJobsCount', 'totalJobCount', 'testsCount'],
  data() {
    return {
      activeTab: this.defaultTabValue,
    };
  },
  computed: {
    showFailedJobsTab() {
      return this.failedJobsCount > 0;
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
  },
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
      ref="dagTab"
      :title="$options.i18n.tabs.needsTitle"
      :active="isActive($options.tabNames.needs)"
      data-testid="dag-tab"
      lazy
      @click="navigateTo($options.tabNames.needs)"
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
    <slot></slot>
  </gl-tabs>
</template>
