import { GlTab } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelineTabs from '~/ci/pipeline_details/tabs/pipeline_tabs.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { TRACKING_CATEGORIES } from '~/ci/constants';

describe('The Pipeline Tabs', () => {
  let wrapper;
  let trackingSpy;

  const $router = { push: jest.fn() };

  const findFailedJobsTab = () => wrapper.findByTestId('failed-jobs-tab');
  const findJobsTab = () => wrapper.findByTestId('jobs-tab');
  const findPipelineTab = () => wrapper.findByTestId('pipeline-tab');
  const findTestsTab = () => wrapper.findByTestId('tests-tab');

  const findFailedJobsBadge = () => wrapper.findByTestId('failed-builds-counter');
  const findJobsBadge = () => wrapper.findByTestId('builds-counter');
  const findTestsBadge = () => wrapper.findByTestId('tests-counter');
  const findManualVariablesTab = () => wrapper.findByTestId('manual-variables-tab');
  const findManualVariablesBadge = () => wrapper.findByTestId('manual-variables-counter');

  const defaultProvide = {
    defaultTabValue: '',
    failedJobsCount: 1,
    totalJobCount: 10,
    testsCount: 123,
    manualVariablesCount: 0,
  };

  const createComponent = (provide = {}, stubs = {}) => {
    wrapper = shallowMountExtended(PipelineTabs, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlTab,
        RouterView: true,
        ...stubs,
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
      ${'Jobs'}        | ${findJobsTab}
      ${'Failed Jobs'} | ${findFailedJobsTab}
      ${'Tests'}       | ${findTestsTab}
    `('shows $tabName tab', ({ tabComponent }) => {
      createComponent();

      expect(tabComponent().exists()).toBe(true);
    });

    describe('Manual Variables tab', () => {
      it('does not render the tab while feature flag is turned off', () => {
        createComponent();

        expect(findManualVariablesTab().exists()).toBe(false);
      });

      it('does not render the tab while the manual variable count given by backend is invalid', () => {
        createComponent({ manualVariablesCount: NaN });

        expect(findManualVariablesTab().exists()).toBe(false);
      });

      it('renders manual variables tab when feature flag is enabled', () => {
        createComponent({
          glFeatures: {
            ciShowManualVariablesInPipeline: true,
          },
        });

        expect(findManualVariablesTab().exists()).toBe(true);
      });
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

    describe('Manual variables tab badge', () => {
      const findLocalStorageComponent = () => wrapper.findComponent(LocalStorageSync);
      const findManualVariableNewBadge = () => wrapper.findByTestId('manual-variables-new-badge');

      beforeEach(() => {
        createComponent(
          {
            glFeatures: {
              ciShowManualVariablesInPipeline: true,
            },
          },
          {
            LocalStorageSync,
          },
        );
      });

      it('renders manual variables tab counter badge', () => {
        const badgeComponent = findManualVariablesBadge();
        expect(badgeComponent.exists()).toBe(true);
        expect(badgeComponent.text()).toBe('0');
      });

      it('renders manual variables tab new badge', async () => {
        const localStorageComponent = findLocalStorageComponent();
        const badgeComponent = findManualVariableNewBadge();

        expect(badgeComponent.exists()).toBe(true);

        localStorageComponent.vm.$emit('input', true);
        await nextTick();

        expect(badgeComponent.exists()).toBe(false);
      });
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

    it('tracks manual variables tab click', () => {
      createComponent({
        glFeatures: {
          ciShowManualVariablesInPipeline: true,
        },
      });

      findManualVariablesTab().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', {
        label: TRACKING_CATEGORIES.manual_variables,
      });
    });
  });
});
