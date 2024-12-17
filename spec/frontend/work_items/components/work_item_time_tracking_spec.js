import { GlProgressBar, GlSprintf } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTimeTracking from '~/work_items/components/work_item_time_tracking.vue';

describe('WorkItemTimeTracking component', () => {
  let wrapper;

  const findAddEstimateButton = () => wrapper.findComponentByTestId('add-estimate-button');
  const findSetEstimateButton = () => wrapper.findComponentByTestId('set-estimate-button');
  const findAddTimeEntryButton = () => wrapper.findComponentByTestId('add-time-entry-button');
  const findButton = (name) => wrapper.findByRole('button', { name });
  const findViewTimeSpentButton = () => wrapper.findComponentByTestId('view-time-spent-button');
  const findEstimateButton = () => wrapper.findComponentByTestId('add-estimate-button');
  const findProgressBar = () => wrapper.findComponent(GlProgressBar);
  const findAddTimeSpentButton = () => wrapper.findComponentByTestId('add-time-spent-button');
  const findTimeTrackingBody = () => wrapper.findByTestId('time-tracking-body');
  const getProgressBarTooltip = () => getBinding(findProgressBar().element, 'gl-tooltip');

  const createComponent = ({ canUpdate = true, timeEstimate = 0, totalTimeSpent = 0 } = {}) => {
    wrapper = shallowMountExtended(WorkItemTimeTracking, {
      directives: {
        GlModal: createMockDirective('gl-modal'),
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        canUpdate,
        timeEstimate,
        totalTimeSpent,
        workItemId: 'gid://gitlab/WorkItem/13',
        workItemIid: '13',
        workItemType: 'Task',
      },
      provide: {
        fullPath: 'gitlab-org/gitlab',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('renders heading text', () => {
    createComponent();

    expect(wrapper.find('h3').text()).toBe('Time tracking');
  });

  describe('"Add time entry" button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders as "plus" icon', () => {
      expect(findAddTimeEntryButton().props('icon')).toBe('plus');
    });

    it('shows tooltip', () => {
      expect(getBinding(findAddTimeEntryButton().element, 'gl-tooltip')).toBeDefined();
      expect(findAddTimeEntryButton().attributes('title')).toBe('Add time entry');
    });

    it('has a modal directive', () => {
      expect(getBinding(findAddTimeEntryButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('create-timelog-modal'),
      );
    });
  });

  describe('with no time spent and no time estimate', () => {
    beforeEach(() => {
      createComponent({ timeEstimate: 0, totalTimeSpent: 0 });
    });

    it('shows help text', () => {
      expect(findTimeTrackingBody().text()).toMatchInterpolatedText(
        'Add an estimate or time spent.',
      );
      expect(findProgressBar().exists()).toBe(false);
    });

    it('allows user to add an estimate by clicking "estimate"', () => {
      expect(findEstimateButton().props('variant')).toBe('link');
      expect(getBinding(findEstimateButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('set-time-estimate-modal'),
      );
    });

    it('allows user to add a time entry by clicking "time spent"', () => {
      expect(findAddTimeSpentButton().props('variant')).toBe('link');
      expect(getBinding(findAddTimeSpentButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('create-timelog-modal'),
      );
    });
  });

  describe('with time spent and no time estimate', () => {
    beforeEach(() => {
      createComponent({ timeEstimate: 0, totalTimeSpent: 10800 });
    });

    it('shows time spent', () => {
      expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 3h Add estimate');
      expect(findProgressBar().exists()).toBe(false);
    });

    it('time spent links to time tracking report', () => {
      expect(findViewTimeSpentButton().props('variant')).toBe('link');
      expect(getBinding(findViewTimeSpentButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('time-tracking-modal'),
      );
      expect(getBinding(findViewTimeSpentButton().element, 'gl-tooltip').value).toBe(
        'View time tracking report',
      );
    });

    it('shows "Add estimate" button to add estimate', () => {
      expect(findAddEstimateButton().props('variant')).toBe('link');
      expect(getBinding(findAddEstimateButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('set-time-estimate-modal'),
      );
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
      expect(getProgressBarTooltip().value).toContain('3h remaining');
    });

    it('estimate links to "Add estimate" modal', () => {
      expect(findSetEstimateButton().props('variant')).toBe('link');
      expect(getBinding(findSetEstimateButton().element, 'gl-modal').value).toEqual(
        expect.stringContaining('set-time-estimate-modal'),
      );
      expect(getBinding(findSetEstimateButton().element, 'gl-tooltip').value).toBe('Set estimate');
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
        expect(getProgressBarTooltip().value).toContain('2h remaining');
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
        expect(getProgressBarTooltip().value).toContain('2h over');
      });
    });
  });

  describe('when user has no permissions', () => {
    it('does not show "Add time entry" button', () => {
      createComponent({ canUpdate: false });

      expect(findAddTimeEntryButton().exists()).toBe(false);
    });

    describe('with no time spent and no time estimate', () => {
      beforeEach(() => {
        createComponent({ canUpdate: false, timeEstimate: 0, totalTimeSpent: 0 });
      });

      it('shows help text', () => {
        expect(findTimeTrackingBody().text()).toBe('No estimate or time spent');
      });

      it('does not allow user to add an estimate by clicking "estimate"', () => {
        expect(findEstimateButton().exists()).toBe(false);
      });

      it('does not allow user to add a time entry by clicking "time spent"', () => {
        expect(findAddTimeSpentButton().exists()).toBe(false);
      });
    });

    describe('with time spent and no time estimate', () => {
      beforeEach(() => {
        createComponent({ canUpdate: false, timeEstimate: 0, totalTimeSpent: 10800 });
      });

      it('shows only time spent', () => {
        expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 3h');
      });

      it('does not link time spent to time tracking report', () => {
        expect(findButton('3h').exists()).toBe(false);
      });

      it('does not show "Add estimate" button to add estimate', () => {
        expect(findAddEstimateButton().exists()).toBe(false);
      });
    });

    describe('with no time spent and time estimate', () => {
      beforeEach(() => {
        createComponent({ canUpdate: false, timeEstimate: 10800, totalTimeSpent: 0 });
      });

      it('shows 0h time spent and time estimate', () => {
        expect(findTimeTrackingBody().text()).toMatchInterpolatedText('Spent 0h Estimate 3h');
      });

      it('does not link estimate to "Add estimate" modal', () => {
        expect(findButton('3h').exists()).toBe(false);
      });
    });
  });
});
