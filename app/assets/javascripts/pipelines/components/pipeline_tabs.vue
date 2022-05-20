<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { __ } from '~/locale';
import { failedJobsTabName, jobsTabName, needsTabName, testReportTabName } from '../constants';
import PipelineGraphWrapper from './graph/graph_component_wrapper.vue';
import Dag from './dag/dag.vue';
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
    FailedJobsApp: JobsApp,
    PipelineGraphWrapper,
    TestReports,
  },
  inject: ['defaultTabValue', 'totalJobCount'],
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
      :title="$options.i18n.tabs.failedJobsTitle"
      :active="isActive($options.tabNames.failures)"
      data-testid="failed-jobs-tab"
      lazy
    >
      <failed-jobs-app />
    </gl-tab>
    <gl-tab
      :title="$options.i18n.tabs.testsTitle"
      :active="isActive($options.tabNames.tests)"
      data-testid="tests-tab"
    >
      <test-reports />
    </gl-tab>
    <slot></slot>
  </gl-tabs>
</template>
