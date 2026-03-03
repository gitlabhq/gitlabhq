import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import JobRow from '~/ci/pipeline_editor/components/graph/job_row.vue';

describe('Job Row', () => {
  let wrapper;

  const defaultProps = {
    jobName: 'test_job',
    pipelineId: 123,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(JobRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findJobRow = () => wrapper.find('div');
  const findJobName = () => wrapper.find('span');
  const findButton = () => wrapper.findComponent(GlButton);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the job name', () => {
      expect(findJobName().text()).toBe(defaultProps.jobName);
    });

    it('renders a div with the correct id', () => {
      expect(findJobRow().attributes('id')).toBe(
        `${defaultProps.jobName}-${defaultProps.pipelineId}`,
      );
    });

    it('renders a menu button', () => {
      expect(findButton().exists()).toBe(true);
      expect(findButton().attributes('icon')).toBe('ellipsis_v');
    });
  });

  describe('when job is faded out', () => {
    beforeEach(() => {
      createComponent({ isFadedOut: true });
    });

    it('applies opacity class to the row', () => {
      expect(findJobRow().classes()).toContain('gl-opacity-3');
    });
  });

  describe('when job is hovered', () => {
    beforeEach(() => {
      createComponent({ isHovered: true });
    });

    it('applies hover styling classes to the row', () => {
      expect(findJobRow().classes()).toContain('gl-bg-strong');
      expect(findJobRow().classes()).toContain('gl-shadow-inner-1-gray-200');
    });
  });

  describe('user interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      action             | event           | eventName           | expectedPayload
      ${'hovers'}        | ${'mouseover'}  | ${'on-mouse-enter'} | ${[defaultProps.jobName]}
      ${'focuses'}       | ${'focus'}      | ${'on-mouse-enter'} | ${[defaultProps.jobName]}
      ${'removes hover'} | ${'mouseleave'} | ${'on-mouse-leave'} | ${[]}
      ${'blurs'}         | ${'blur'}       | ${'on-mouse-leave'} | ${[]}
    `('emits $eventName when user $action the job row', ({ event, eventName, expectedPayload }) => {
      if (event === 'focus') {
        findJobRow().element.dispatchEvent(new FocusEvent(event));
      } else {
        findJobRow().trigger(event);
      }

      expect(wrapper.emitted(eventName)).toHaveLength(1);
      expect(wrapper.emitted(eventName)[0]).toEqual(expectedPayload);
    });
  });
});
