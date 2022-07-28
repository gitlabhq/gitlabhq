import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
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

  const findFailedJobsBadge = () => wrapper.findByTestId('failed-builds-counter');
  const findJobsBadge = () => wrapper.findByTestId('builds-counter');
  const findTestsBadge = () => wrapper.findByTestId('tests-counter');

  const defaultProvide = {
    defaultTabValue: '',
    failedJobsCount: 1,
    failedJobsSummary: [],
    totalJobCount: 10,
    testsCount: 123,
  };

  const createComponent = (provide = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineTabs, {
        provide: {
          ...defaultProvide,
          ...provide,
        },
        stubs: {
          GlTab,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Tabs', () => {
    it.each`
      tabName          | tabComponent         | appComponent
      ${'Pipeline'}    | ${findPipelineTab}   | ${findPipelineApp}
      ${'Dag'}         | ${findDagTab}        | ${findDagApp}
      ${'Jobs'}        | ${findJobsTab}       | ${findJobsApp}
      ${'Failed Jobs'} | ${findFailedJobsTab} | ${findFailedJobsApp}
      ${'Tests'}       | ${findTestsTab}      | ${findTestsApp}
    `('shows $tabName tab with its associated component', ({ appComponent, tabComponent }) => {
      createComponent();

      expect(tabComponent().exists()).toBe(true);
      expect(appComponent().exists()).toBe(true);
    });

    describe('with no failed jobs', () => {
      beforeEach(() => {
        createComponent({ failedJobsCount: 0 });
      });

      it('hides the failed jobs tab', () => {
        expect(findFailedJobsTab().exists()).toBe(false);
      });
    });
  });

  describe('Tabs badges', () => {
    it.each`
      tabName          | badgeComponent         | badgeText
      ${'Jobs'}        | ${findJobsBadge}       | ${String(defaultProvide.totalJobCount)}
      ${'Failed Jobs'} | ${findFailedJobsBadge} | ${String(defaultProvide.failedJobsCount)}
      ${'Tests'}       | ${findTestsBadge}      | ${String(defaultProvide.testsCount)}
    `('shows badge for $tabName with the correct text', ({ badgeComponent, badgeText }) => {
      createComponent();

      expect(badgeComponent().exists()).toBe(true);
      expect(badgeComponent().text()).toBe(badgeText);
    });
  });
});
