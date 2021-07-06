import { mount } from '@vue/test-utils';

import { stubTransition } from 'helpers/stub_transition';
import { createMockDirective } from 'helpers/vue_mock_directive';
import TimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';
import SidebarEventHub from '~/sidebar/event_hub';

import { issuableTimeTrackingResponse } from '../../mock_data';

describe('Issuable Time Tracker', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid=${testId}]`);
  const findComparisonMeter = () => findByTestId('compareMeter').attributes('title');
  const findCollapsedState = () => findByTestId('collapsedState');
  const findTimeRemainingProgress = () => findByTestId('timeRemainingProgress');
  const findReportLink = () => findByTestId('reportLink');

  const defaultProps = {
    limitToHours: false,
    fullPath: 'gitlab-org/gitlab-test',
    issuableId: '1',
    issuableIid: '1',
    initialTimeTracking: {
      ...issuableTimeTrackingResponse.data.workspace.issuable,
    },
  };

  const issuableTimeTrackingRefetchSpy = jest.fn();

  const mountComponent = ({ props = {}, issuableType = 'issue', loading = false } = {}) => {
    return mount(TimeTracker, {
      propsData: { ...defaultProps, ...props },
      directives: { GlTooltip: createMockDirective() },
      stubs: {
        transition: stubTransition(),
      },
      provide: {
        issuableType,
      },
      mocks: {
        $apollo: {
          queries: {
            issuableTimeTracking: {
              loading,
              refetch: issuableTimeTrackingRefetchSpy,
              query: jest.fn().mockResolvedValue(issuableTimeTrackingResponse),
            },
          },
        },
      },
    });
  };

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
        defaultProps.initialTimeTracking.humanTimeEstimate,
      );
    });

    it('should correctly render totalTimeSpent', () => {
      expect(findByTestId('timeTrackingComparisonPane').html()).toContain(
        defaultProps.initialTimeTracking.humanTotalTimeSpent,
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
            initialTimeTracking: {
              timeEstimate: 100_000, // 1d 3h
              totalTimeSpent: 5_000, // 1h 23m
              humanTimeEstimate: '1d 3h',
              humanTotalTimeSpent: '1h 23m',
            },
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
              initialTimeTracking: {
                ...defaultProps.initialTimeTracking,
                timeEstimate: 10_000, // 2h 46m
                totalTimeSpent: 20_000_000, // 231 days
              },
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
            limitToHours: true,
            initialTimeTracking: {
              ...defaultProps.initialTimeTracking,
              timeEstimate: 100_000, // 1d 3h
            },
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
            initialTimeTracking: {
              timeEstimate: 10_000, // 2h 46m
              totalTimeSpent: 0,
              humanTimeEstimate: '2h 46m',
              humanTotalTimeSpent: '',
            },
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
            initialTimeTracking: {
              timeEstimate: 0,
              totalTimeSpent: 5_000, // 1h 23m
              humanTimeEstimate: '2h 46m',
              humanTotalTimeSpent: '1h 23m',
            },
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
            initialTimeTracking: {
              timeEstimate: 0,
              totalTimeSpent: 0,
              humanTimeEstimate: '',
              humanTotalTimeSpent: '',
            },
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
              initialTimeTracking: {
                ...defaultProps.initialTimeTracking,
                totalTimeSpent: 0,
                humanTotalTimeSpent: '',
              },
            },
          });
        });

        it('link should not appear', () => {
          expect(findReportLink().exists()).toBe(false);
        });
      });

      describe('When time spent', () => {
        it('link should appear on issue', () => {
          wrapper = mountComponent();
          expect(findReportLink().exists()).toBe(true);
        });

        it('link should appear on merge request', () => {
          wrapper = mountComponent({ issuableType: 'merge_request' });
          expect(findReportLink().exists()).toBe(true);
        });

        it('link should not appear on milestone', () => {
          wrapper = mountComponent({ issuableType: 'milestone' });
          expect(findReportLink().exists()).toBe(false);
        });
      });
    });

    describe('Help pane', () => {
      const findHelpButton = () => findByTestId('helpButton');
      const findCloseHelpButton = () => findByTestId('closeHelpButton');

      beforeEach(async () => {
        wrapper = mountComponent({
          props: {
            initialTimeTracking: {
              timeEstimate: 0,
              totalTimeSpent: 0,
              humanTimeEstimate: '',
              humanTotalTimeSpent: '',
            },
          },
        });
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

  describe('Event listeners', () => {
    it('refetches issuableTimeTracking query when eventHub emits `timeTracker:refresh` event', async () => {
      SidebarEventHub.$emit('timeTracker:refresh');

      await wrapper.vm.$nextTick();

      expect(issuableTimeTrackingRefetchSpy).toHaveBeenCalled();
    });
  });
});
