import { shallowMount } from '@vue/test-utils';
import JobPill from '~/ci/pipeline_editor/components/graph/job_pill.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

describe('Job Pill', () => {
  let wrapper;

  const defaultProps = {
    jobName: 'test_job',
    pipelineId: 123,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(JobPill, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findButton = () => wrapper.find('button');
  const findTooltipOnTruncate = () => wrapper.findComponent(TooltipOnTruncate);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the job name', () => {
      expect(findButton().text()).toBe(defaultProps.jobName);
    });

    it('renders the job label', () => {
      expect(findButton().attributes('aria-label')).toBe(`${defaultProps.jobName} job`);
    });

    it('renders a button with the correct id', () => {
      expect(findButton().attributes('id')).toBe(
        `${defaultProps.jobName}-${defaultProps.pipelineId}`,
      );
    });

    it('passes the job name as tooltip title', () => {
      expect(findTooltipOnTruncate().attributes('title')).toBe(defaultProps.jobName);
    });
  });

  describe('when job is faded out', () => {
    beforeEach(() => {
      createComponent({ isFadedOut: true });
    });

    it('applies opacity class to the button', () => {
      expect(findButton().classes()).toContain('gl-opacity-3');
    });
  });

  describe('when job is hovered', () => {
    beforeEach(() => {
      createComponent({ isHovered: true });
    });

    it('applies hover styling classes to the button', () => {
      expect(findButton().classes()).toContain('gl-bg-strong');
      expect(findButton().classes()).toContain('gl-shadow-inner-1-gray-200');
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
    `(
      'emits $eventName when user $action the job pill',
      ({ event, eventName, expectedPayload }) => {
        if (event === 'focus') {
          findButton().element.dispatchEvent(new FocusEvent(event));
        } else {
          findButton().trigger(event);
        }

        expect(wrapper.emitted(eventName)).toHaveLength(1);
        expect(wrapper.emitted(eventName)[0]).toEqual(expectedPayload);
      },
    );
  });
});
