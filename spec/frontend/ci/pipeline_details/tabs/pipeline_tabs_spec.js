import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelineTabs from '~/ci/pipeline_details/tabs/pipeline_tabs.vue';
import { TRACKING_CATEGORIES } from '~/ci/constants';

describe('The Pipeline Tabs', () => {
  let wrapper;
  let trackingSpy;

  const $router = { push: jest.fn() };

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
    wrapper = shallowMountExtended(PipelineTabs, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlTab,
        RouterView: true,
      },
      mocks: {
        $router,
      },
    });
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

  describe('Tab tracking', () => {
    beforeEach(() => {
      createComponent();

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks failed jobs tab click', () => {
      findFailedJobsTab().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', {
        label: TRACKING_CATEGORIES.failed,
      });
    });

    it('tracks tests tab click', () => {
      findTestsTab().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', {
        label: TRACKING_CATEGORIES.tests,
      });
    });
  });
});
