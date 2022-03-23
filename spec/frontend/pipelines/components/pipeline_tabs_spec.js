import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineTabs from '~/pipelines/components/pipeline_tabs.vue';
import PipelineGraphWrapper from '~/pipelines/components/graph/graph_component_wrapper.vue';
import Dag from '~/pipelines/components/dag/dag.vue';
import JobsApp from '~/pipelines/components/jobs/jobs_app.vue';
import TestReports from '~/pipelines/components/test_reports/test_reports.vue';

describe('The Pipeline Tabs', () => {
  let wrapper;

  const findDagTab = () => wrapper.findByTestId('dag-tab');
  const findFailedJobsTab = () => wrapper.findByTestId('failed-jobs-tab');
  const findJobsTab = () => wrapper.findByTestId('jobs-tab');
  const findPipelineTab = () => wrapper.findByTestId('pipeline-tab');
  const findTestsTab = () => wrapper.findByTestId('tests-tab');

  const findDagApp = () => wrapper.findComponent(Dag);
  const findFailedJobsApp = () => wrapper.findComponent(JobsApp);
  const findJobsApp = () => wrapper.findComponent(JobsApp);
  const findPipelineApp = () => wrapper.findComponent(PipelineGraphWrapper);
  const findTestsApp = () => wrapper.findComponent(TestReports);

  const createComponent = (propsData = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineTabs, {
        propsData,
        stubs: {
          Dag: { template: '<div id="dag"/>' },
          JobsApp: { template: '<div class="jobs" />' },
          PipelineGraph: { template: '<div id="graph" />' },
          TestReports: { template: '<div id="tests" />' },
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  // The failed jobs MUST be removed from here and tested individually once
  // the logic for the tab is implemented.
  describe('Tabs', () => {
    it.each`
      tabName          | tabComponent         | appComponent
      ${'Pipeline'}    | ${findPipelineTab}   | ${findPipelineApp}
      ${'Dag'}         | ${findDagTab}        | ${findDagApp}
      ${'Jobs'}        | ${findJobsTab}       | ${findJobsApp}
      ${'Failed Jobs'} | ${findFailedJobsTab} | ${findFailedJobsApp}
      ${'Tests'}       | ${findTestsTab}      | ${findTestsApp}
    `('shows $tabName tab and its associated component', ({ appComponent, tabComponent }) => {
      expect(tabComponent().exists()).toBe(true);
      expect(appComponent().exists()).toBe(true);
    });
  });
});
