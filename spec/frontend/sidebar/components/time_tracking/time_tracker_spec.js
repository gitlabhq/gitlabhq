import { mount } from '@vue/test-utils';
import { stubTransition } from 'helpers/stub_transition';
import { createMockDirective } from 'helpers/vue_mock_directive';
import TimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';

describe('Issuable Time Tracker', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid=${testId}]`);
  const findComparisonMeter = () => findByTestId('compareMeter').attributes('title');
  const findCollapsedState = () => findByTestId('collapsedState');
  const findTimeRemainingProgress = () => findByTestId('timeRemainingProgress');
  const findReportLink = () => findByTestId('reportLink');

  const defaultProps = {
    timeEstimate: 10_000, // 2h 46m
    timeSpent: 5_000, // 1h 23m
    humanTimeEstimate: '2h 46m',
    humanTimeSpent: '1h 23m',
    limitToHours: false,
  };

  const mountComponent = ({ props = {} } = {}) =>
    mount(TimeTracker, {
      propsData: { ...defaultProps, ...props },
      directives: { GlTooltip: createMockDirective() },
      stubs: {
        transition: stubTransition(),
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Initialization', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('should return something defined', () => {
      expect(wrapper).toBeDefined();
    });

    it('should correctly render timeEstimate', () => {
      expect(findByTestId('timeTrackingComparisonPane').html()).toContain(
        defaultProps.humanTimeEstimate,
      );
    });

    it('should correctly render time_spent', () => {
      expect(findByTestId('timeTrackingComparisonPane').html()).toContain(
        defaultProps.humanTimeSpent,
      );
    });
  });

  describe('Content panes', () => {
    describe('Collapsed state', () => {
      it('should render "time-tracking-collapsed-state" by default when "showCollapsed" prop is not specified', () => {
        wrapper = mountComponent();

        expect(findCollapsedState().exists()).toBe(true);
      });

      it('should not render "time-tracking-collapsed-state" when "showCollapsed" is false', () => {
        wrapper = mountComponent({
          props: {
            showCollapsed: false,
          },
        });

        expect(findCollapsedState().exists()).toBe(false);
      });
    });

    describe('Comparison pane', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            timeEstimate: 100_000, // 1d 3h
            timeSpent: 5_000, // 1h 23m
            humanTimeEstimate: '1d 3h',
            humanTimeSpent: '1h 23m',
          },
        });
      });

      it('should show the "Comparison" pane when timeEstimate and time_spent are truthy', () => {
        const pane = findByTestId('timeTrackingComparisonPane');
        expect(pane.exists()).toBe(true);
        expect(pane.isVisible()).toBe(true);
      });

      it('should show full times when the sidebar is collapsed', () => {
        expect(findCollapsedState().text()).toBe('1h 23m / 1d 3h');
      });

      describe('Remaining meter', () => {
        it('should display the remaining meter with the correct width', () => {
          expect(findTimeRemainingProgress().attributes('value')).toBe('5');
        });

        it('should display the remaining meter with the correct background color when within estimate', () => {
          expect(findTimeRemainingProgress().attributes('variant')).toBe('primary');
        });

        it('should display the remaining meter with the correct background color when over estimate', () => {
          wrapper = mountComponent({
            props: {
              timeEstimate: 10_000, // 2h 46m
              timeSpent: 20_000_000, // 231 days
            },
          });

          expect(findTimeRemainingProgress().attributes('variant')).toBe('danger');
        });
      });
    });

    describe('Comparison pane when limitToHours is true', () => {
      beforeEach(async () => {
        wrapper = mountComponent({
          props: {
            timeEstimate: 100_000, // 1d 3h
            limitToHours: true,
          },
        });
      });

      it('should show the correct tooltip text', async () => {
        expect(findByTestId('timeTrackingComparisonPane').exists()).toBe(true);
        await wrapper.vm.$nextTick();

        expect(findComparisonMeter()).toBe('Time remaining: 26h 23m');
      });
    });

    describe('Estimate only pane', () => {
      beforeEach(async () => {
        wrapper = mountComponent({
          props: {
            timeEstimate: 10_000, // 2h 46m
            timeSpent: 0,
            timeEstimateHumanReadable: '2h 46m',
            timeSpentHumanReadable: '',
          },
        });
        await wrapper.vm.$nextTick();
      });

      it('should display the human readable version of time estimated', () => {
        const estimateText = findByTestId('estimateOnlyPane').text();
        expect(estimateText.trim()).toBe('Estimated: 2h 46m');
      });
    });

    describe('Spent only pane', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            timeEstimate: 0,
            timeSpent: 5_000, // 1h 23m
            timeEstimateHumanReadable: '2h 46m',
            timeSpentHumanReadable: '1h 23m',
          },
        });
      });

      it('should display the human readable version of time spent', () => {
        const spentText = findByTestId('spentOnlyPane').text();
        expect(spentText.trim()).toBe('Spent: 1h 23m');
      });
    });

    describe('No time tracking pane', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          props: {
            timeEstimate: 0,
            timeSpent: 0,
            timeEstimateHumanReadable: '',
            timeSpentHumanReadable: '',
          },
        });
      });

      it('should only show the "No time tracking" pane when both timeEstimate and time_spent are falsey', () => {
        const pane = findByTestId('noTrackingPane');
        const correctText = 'No estimate or time spent';
        expect(pane.exists()).toBe(true);
        expect(pane.text().trim()).toBe(correctText);
      });
    });

    describe('Time tracking report', () => {
      describe('When no time spent', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            props: {
              timeSpent: 0,
              timeSpentHumanReadable: '',
            },
          });
        });

        it('link should not appear', () => {
          expect(findReportLink().exists()).toBe(false);
        });
      });

      describe('When time spent', () => {
        beforeEach(() => {
          wrapper = mountComponent();
        });

        it('link should appear', () => {
          expect(findReportLink().exists()).toBe(true);
        });
      });
    });

    describe('Help pane', () => {
      const findHelpButton = () => findByTestId('helpButton');
      const findCloseHelpButton = () => findByTestId('closeHelpButton');

      beforeEach(async () => {
        wrapper = mountComponent({ props: { timeEstimate: 0, timeSpent: 0 } });
        await wrapper.vm.$nextTick();
      });

      it('should not show the "Help" pane by default', () => {
        expect(findByTestId('helpPane').exists()).toBe(false);
      });

      it('should show the "Help" pane when help button is clicked', async () => {
        findHelpButton().trigger('click');

        await wrapper.vm.$nextTick();

        expect(findByTestId('helpPane').exists()).toBe(true);
      });

      it('should not show the "Help" pane when help button is clicked and then closed', async () => {
        findHelpButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(findByTestId('helpPane').exists()).toBe(true);

        findCloseHelpButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(findByTestId('helpPane').exists()).toBe(false);
      });
    });
  });
});
