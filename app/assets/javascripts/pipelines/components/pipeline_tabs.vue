<script>
import { GlTabs, GlTab } from '@gitlab/ui';
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
    GlTab,
    GlTabs,
    JobsApp,
    FailedJobsApp: JobsApp,
    PipelineGraphWrapper,
    TestReports,
  },
  inject: ['defaultTabValue'],
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
    <gl-tab
      :title="$options.i18n.tabs.jobsTitle"
      :active="isActive($options.tabNames.jobs)"
      data-testid="jobs-tab"
    >
      <jobs-app />
    </gl-tab>
    <gl-tab
      :title="$options.i18n.tabs.failedJobsTitle"
      :active="isActive($options.tabNames.failures)"
      data-testid="failed-jobs-tab"
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
