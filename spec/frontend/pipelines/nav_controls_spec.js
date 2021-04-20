import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NavControls from '~/pipelines/components/pipelines_list/nav_controls.vue';

describe('Pipelines Nav Controls', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(NavControls, {
      propsData: {
        ...props,
      },
    });
  };

  const findRunPipeline = () => wrapper.find('.js-run-pipeline');

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render link to create a new pipeline', () => {
    const mockData = {
      newPipelinePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    const runPipeline = findRunPipeline();
    expect(runPipeline.text()).toContain('Run pipeline');
    expect(runPipeline.attributes('href')).toBe(mockData.newPipelinePath);
  });

  it('should not render link to create pipeline if no path is provided', () => {
    const mockData = {
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    expect(findRunPipeline().exists()).toBe(false);
  });

  it('should render link for CI lint', () => {
    const mockData = {
      newPipelinePath: 'foo',
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    expect(wrapper.find('.js-ci-lint').text().trim()).toContain('CI lint');
    expect(wrapper.find('.js-ci-lint').attributes('href')).toBe(mockData.ciLintPath);
  });

  describe('Reset Runners Cache', () => {
    beforeEach(() => {
      const mockData = {
        newPipelinePath: 'foo',
        ciLintPath: 'foo',
        resetCachePath: 'foo',
      };
      createComponent(mockData);
    });

    it('should render button for resetting runner caches', () => {
      expect(wrapper.find('.js-clear-cache').text().trim()).toContain('Clear runner caches');
    });

    it('should emit postAction event when reset runner cache button is clicked', async () => {
      jest.spyOn(wrapper.vm, '$emit').mockImplementation(() => {});

      wrapper.find('.js-clear-cache').vm.$emit('click');
      await nextTick();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('resetRunnersCache', 'foo');
    });
  });
});
