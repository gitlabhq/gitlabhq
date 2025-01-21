import { mount } from '@vue/test-utils';

import { nextTick } from 'vue';
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
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
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
          expect(findTimeRemainingProgress().props('value')).toBe(5);
        });

        it('should display the remaining meter with the correct background color when within estimate', () => {
          expect(findTimeRemainingProgress().props('variant')).toBe('primary');
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

          expect(findTimeRemainingProgress().props('variant')).toBe('danger');
        });
      });
    });

    describe('Comparison pane when limitToHours is true', () => {
      beforeEach(() => {
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
        await nextTick();

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
        await nextTick();
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

    describe('Add button', () => {
      const findAddButton = () => findByTestId('add-time-entry-button');

      it.each`
        visibility       | canAddTimeEntries
        ${'not visible'} | ${false}
        ${'visible'}     | ${true}
      `(
        'is $visibility when canAddTimeEntries is $canAddTimeEntries',
        async ({ canAddTimeEntries }) => {
          wrapper = mountComponent({
            props: {
              initialTimeTracking: {
                timeEstimate: 0,
                totalTimeSpent: 0,
                humanTimeEstimate: '',
                humanTotalTimeSpent: '',
              },
              canAddTimeEntries,
            },
          });
          await nextTick();

          expect(findAddButton().exists()).toBe(canAddTimeEntries);
        },
      );
    });

    describe('Set time estimate button', () => {
      const findSetTimeEstimateButton = () => findByTestId('set-time-estimate-button');

      it.each`
        visibility       | canSetTimeEstimate
        ${'not visible'} | ${false}
        ${'visible'}     | ${true}
      `(
        'is $visibility when canSetTimeEstimate is $canSetTimeEstimate',
        async ({ canSetTimeEstimate }) => {
          wrapper = mountComponent({
            props: {
              initialTimeTracking: {
                timeEstimate: 0,
                totalTimeSpent: 0,
                humanTimeEstimate: '',
                humanTotalTimeSpent: '',
              },
              canSetTimeEstimate,
            },
          });
          await nextTick();

          expect(findSetTimeEstimateButton().exists()).toBe(canSetTimeEstimate);
        },
      );

      it('shows a tooltip with `Set estimate` when the current estimate is 0', async () => {
        wrapper = mountComponent({
          props: {
            initialTimeTracking: {
              timeEstimate: 0,
              totalTimeSpent: 0,
              humanTimeEstimate: '',
              humanTotalTimeSpent: '',
            },
            canSetTimeEstimate: true,
          },
        });
        await nextTick();

        expect(findSetTimeEstimateButton().attributes('title')).toBe('Set estimate');
      });

      it('shows a tooltip with `Edit estimate` when the current estimate is not 0', async () => {
        wrapper = mountComponent({
          props: {
            initialTimeTracking: {
              timeEstimate: 60,
              totalTimeSpent: 0,
              humanTimeEstimate: '1m',
              humanTotalTimeSpent: '',
            },
            canSetTimeEstimate: true,
          },
        });
        await nextTick();

        expect(findSetTimeEstimateButton().attributes('title')).toBe('Edit estimate');
      });
    });
  });

  describe('Event listeners', () => {
    it('refetches issuableTimeTracking query when eventHub emits `timeTracker:refresh` event', async () => {
      SidebarEventHub.$emit('timeTracker:refresh');

      await nextTick();

      expect(issuableTimeTrackingRefetchSpy).toHaveBeenCalled();
    });
  });
});
