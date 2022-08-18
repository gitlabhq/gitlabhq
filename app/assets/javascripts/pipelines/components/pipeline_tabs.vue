<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { __ } from '~/locale';
import { failedJobsTabName, jobsTabName, needsTabName, testReportTabName } from '../constants';
import PipelineGraphWrapper from './graph/graph_component_wrapper.vue';
import Dag from './dag/dag.vue';
import FailedJobsApp from './jobs/failed_jobs_app.vue';
import JobsApp from './jobs/jobs_app.vue';
import TestReports from './test_reports/test_reports.vue';

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
    needs: needsTabName,
    jobs: jobsTabName,
    failures: failedJobsTabName,
    tests: testReportTabName,
  },
  components: {
    Dag,
    GlBadge,
    GlTab,
    GlTabs,
    JobsApp,
    FailedJobsApp,
    PipelineGraphWrapper,
    TestReports,
  },
  inject: [
    'defaultTabValue',
    'failedJobsCount',
    'failedJobsSummary',
    'totalJobCount',
    'testsCount',
  ],
  computed: {
    showFailedJobsTab() {
      return this.failedJobsCount > 0;
    },
  },
  methods: {
    isActive(tabName) {
      return tabName === this.defaultTabValue;
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab ref="pipelineTab" :title="$options.i18n.tabs.pipelineTitle" data-testid="pipeline-tab">
      <pipeline-graph-wrapper />
    </gl-tab>
    <gl-tab
      ref="dagTab"
      :title="$options.i18n.tabs.needsTitle"
      :active="isActive($options.tabNames.needs)"
      data-testid="dag-tab"
    >
      <dag />
    </gl-tab>
    <gl-tab :active="isActive($options.tabNames.jobs)" data-testid="jobs-tab" lazy>
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.jobsTitle }}</span>
        <gl-badge size="sm" data-testid="builds-counter">{{ totalJobCount }}</gl-badge>
      </template>
      <jobs-app />
    </gl-tab>
    <gl-tab
      v-if="showFailedJobsTab"
      :title="$options.i18n.tabs.failedJobsTitle"
      :active="isActive($options.tabNames.failures)"
      data-testid="failed-jobs-tab"
      lazy
    >
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.failedJobsTitle }}</span>
        <gl-badge size="sm" data-testid="failed-builds-counter">{{ failedJobsCount }}</gl-badge>
      </template>
      <failed-jobs-app :failed-jobs-summary="failedJobsSummary" />
    </gl-tab>
    <gl-tab :active="isActive($options.tabNames.tests)" data-testid="tests-tab" lazy>
      <template #title>
        <span class="gl-mr-2">{{ $options.i18n.tabs.testsTitle }}</span>
        <gl-badge size="sm" data-testid="tests-counter">{{ testsCount }}</gl-badge>
      </template>
      <test-reports />
    </gl-tab>
    <slot></slot>
  </gl-tabs>
</template>
