import { GlProgressBar } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTimeTracking from '~/work_items/components/work_item_time_tracking.vue';

describe('WorkItemTimeTracking component', () => {
  let wrapper;

  const findProgressBar = () => wrapper.findComponent(GlProgressBar);
  const findTimeTrackingBody = () => wrapper.findByTestId('time-tracking-body');
  const getTooltip = () => getBinding(findProgressBar().element, 'gl-tooltip');

  const createComponent = ({ timeEstimate = 0, totalTimeSpent = 0 } = {}) => {
    wrapper = shallowMountExtended(WorkItemTimeTracking, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        timeEstimate,
        totalTimeSpent,
      },
    });
  };

  it('renders heading text', () => {
    createComponent();

    expect(wrapper.find('h3').text()).toBe('Time tracking');
  });

  describe('with no time spent and no time estimate', () => {
    it('shows help text', () => {
      createComponent({ timeEstimate: 0, totalTimeSpent: 0 });

      expect(findTimeTrackingBody().text()).toMatchInterpolatedText(
        'To manage time, use /spend or /estimate.',
      );
      expect(findProgressBar().exists()).toBe(false);
    });
  });

  describe('with time spent and no time estimate', () => {
    it('shows only time spent', () => {
      createComponent({ timeEstimate: 0, totalTimeSpent: 10800 });

      expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 3h');
      expect(findProgressBar().exists()).toBe(false);
    });
  });

  describe('with no time spent and time estimate', () => {
    beforeEach(() => {
      createComponent({ timeEstimate: 10800, totalTimeSpent: 0 });
    });

    it('shows 0h time spent and time estimate', () => {
      expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 0h Estimate 3h');
    });

    it('shows progress bar with tooltip', () => {
      expect(findProgressBar().attributes()).toMatchObject({
        value: '0',
        variant: 'primary',
      });
      expect(getTooltip().value).toContain('3h remaining');
    });
  });

  describe('with time spent and time estimate', () => {
    describe('when time spent is less than the time estimate', () => {
      beforeEach(() => {
        createComponent({ timeEstimate: 18000, totalTimeSpent: 10800 });
      });

      it('shows time spent and time estimate', () => {
        expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 3h Estimate 5h');
      });

      it('shows progress bar with tooltip', () => {
        expect(findProgressBar().attributes()).toMatchObject({
          value: '60',
          variant: 'primary',
        });
        expect(getTooltip().value).toContain('2h remaining');
      });
    });

    describe('when time spent is greater than the time estimate', () => {
      beforeEach(() => {
        createComponent({ timeEstimate: 10800, totalTimeSpent: 18000 });
      });

      it('shows time spent and time estimate', () => {
        expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 5h Estimate 3h');
      });

      it('shows progress bar with tooltip', () => {
        expect(findProgressBar().attributes()).toMatchObject({
          value: '166',
          variant: 'danger',
        });
        expect(getTooltip().value).toContain('2h over');
      });
    });
  });
});
