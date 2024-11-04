import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavControls from '~/ci/pipelines_page/components/nav_controls.vue';

describe('Pipelines Nav Controls', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(NavControls, {
      propsData: {
        ...props,
      },
      provide: {
        pipelinesAnalyticsPath: '/pipelines/charts',
      },
    });
  };

  const findRunPipelineButton = () => wrapper.findByTestId('run-pipeline-button');
  const findClearCacheButton = () => wrapper.findByTestId('clear-cache-button');
  const findViewAnalyticsLink = () => wrapper.findByTestId('view-analytics-link');

  it('should render link to navigate to CI/CD analytics', () => {
    createComponent();

    const link = findViewAnalyticsLink();

    expect(link.exists()).toBe(true);
    expect(link.text()).toContain('View analytics');
    expect(link.attributes('href')).toBe('/pipelines/charts');
  });

  it('should render link to create a new pipeline', () => {
    const mockData = {
      newPipelinePath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    const runPipelineButton = findRunPipelineButton();
    expect(runPipelineButton.text()).toContain('New pipeline');
    expect(runPipelineButton.attributes('href')).toBe(mockData.newPipelinePath);
  });

  it('should not render link to create pipeline if no path is provided', () => {
    const mockData = {
      helpPagePath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    expect(findRunPipelineButton().exists()).toBe(false);
  });

  describe('Reset Runners Cache', () => {
    beforeEach(() => {
      const mockData = {
        newPipelinePath: 'foo',
        resetCachePath: 'foo',
      };
      createComponent(mockData);
    });

    it('should render button for resetting runner caches', () => {
      expect(findClearCacheButton().text()).toContain('Clear runner caches');
    });

    it('should emit postAction event when reset runner cache button is clicked', () => {
      findClearCacheButton().vm.$emit('click');

      expect(wrapper.emitted('resetRunnersCache')).toEqual([['foo']]);
    });
  });
});
