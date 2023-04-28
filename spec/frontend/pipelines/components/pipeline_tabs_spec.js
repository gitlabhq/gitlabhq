import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineTabs from '~/pipelines/components/pipeline_tabs.vue';

describe('The Pipeline Tabs', () => {
  let wrapper;

  const findDagTab = () => wrapper.findByTestId('dag-tab');
  const findFailedJobsTab = () => wrapper.findByTestId('failed-jobs-tab');
  const findJobsTab = () => wrapper.findByTestId('jobs-tab');
  const findPipelineTab = () => wrapper.findByTestId('pipeline-tab');
  const findTestsTab = () => wrapper.findByTestId('tests-tab');

  const findFailedJobsBadge = () => wrapper.findByTestId('failed-builds-counter');
  const findJobsBadge = () => wrapper.findByTestId('builds-counter');
  const findTestsBadge = () => wrapper.findByTestId('tests-counter');

  const defaultProvide = {
    defaultTabValue: '',
    failedJobsCount: 1,
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
          RouterView: true,
        },
      }),
    );
  };

  describe('Tabs', () => {
    it.each`
      tabName          | tabComponent
      ${'Pipeline'}    | ${findPipelineTab}
      ${'Dag'}         | ${findDagTab}
      ${'Jobs'}        | ${findJobsTab}
      ${'Failed Jobs'} | ${findFailedJobsTab}
      ${'Tests'}       | ${findTestsTab}
    `('shows $tabName tab', ({ tabComponent }) => {
      createComponent();

      expect(tabComponent().exists()).toBe(true);
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
