import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATUS_CLOSED } from '~/issues/constants';
import IssueCardTimeInfo from '~/issues/list/components/issue_card_time_info.vue';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import {
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_TIME_TRACKING,
} from '~/work_items/constants';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('CE IssueCardTimeInfo component', () => {
  let wrapper;

  const issueObject = ({
    milestoneStartDate,
    milestoneDueDate,
    dueDate,
    state,
    timeEstimate,
  } = {}) => ({
    milestone: {
      dueDate: milestoneDueDate,
      startDate: milestoneStartDate,
      title: 'My milestone',
      webPath: '/milestone/webPath',
    },
    dueDate,
    humanTimeEstimate: timeEstimate,
    state,
  });

  const workItemObject = ({
    milestoneStartDate,
    milestoneDueDate,
    startDate,
    dueDate,
    state,
    timeEstimate,
  } = {}) => ({
    state,
    widgets: [
      {
        type: WIDGET_TYPE_MILESTONE,
        milestone: {
          dueDate: milestoneDueDate,
          startDate: milestoneStartDate,
          title: 'My milestone',
          webPath: '/milestone/webPath',
        },
      },
      {
        type: WIDGET_TYPE_START_AND_DUE_DATE,
        dueDate,
        startDate,
      },
      {
        type: WIDGET_TYPE_TIME_TRACKING,
        humanReadableAttributes: {
          timeEstimate,
        },
      },
    ],
  });

  const findMilestone = () => wrapper.findComponent(IssuableMilestone);
  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);
  const findDueDateIcon = () => wrapper.findByTestId('issuable-due-date').findComponent(GlIcon);

  const mountComponent = ({ issue = issueObject(), hiddenMetadataKeys = [] } = {}) =>
    shallowMountExtended(IssueCardTimeInfo, {
      propsData: { issue, hiddenMetadataKeys },
      stubs: {
        WorkItemAttribute,
      },
    });

  describe.each`
    type           | object
    ${'issue'}     | ${issueObject}
    ${'work item'} | ${workItemObject}
  `('with $type object', ({ object }) => {
    describe('milestone', () => {
      it('renders', () => {
        wrapper = mountComponent({ issue: object() });

        const milestone = findMilestone();

        expect(milestone.exists()).toBe(true);
      });

      it('hides milestone when included in hiddenMetadataKeys', () => {
        wrapper = mountComponent({
          issue: object(),
          hiddenMetadataKeys: ['milestone'],
        });

        expect(findMilestone().exists()).toBe(false);
      });
    });

    describe('due date', () => {
      describe('when upcoming', () => {
        it('renders with "No start date" prefix when no start date is present', () => {
          wrapper = mountComponent({ issue: object({ dueDate: '2020-12-12' }) });
          expect(findWorkItemAttribute().props('title')).toBe('No start date – Dec 12, 2020');
          expect(findWorkItemAttribute().props('tooltipText')).toBe('Dates');
          expect(findDueDateIcon().props()).toMatchObject({
            variant: 'current',
            name: 'calendar',
          });
        });

        it('hides dates when included in hiddenMetadataKeys', () => {
          wrapper = mountComponent({
            issue: object({ dueDate: '2020-12-12' }),
            hiddenMetadataKeys: ['dates'],
          });

          expect(findWorkItemAttribute().exists()).toBe(false);
        });
      });

      describe('when in the past', () => {
        describe('when issue is open', () => {
          it('renders in red with overdue icon and "No start date" prefix', () => {
            wrapper = mountComponent({ issue: object({ dueDate: '2020-01-01' }) });
            expect(findWorkItemAttribute().props('title')).toBe('No start date – Jan 1, 2020');
            expect(findDueDateIcon().props()).toMatchObject({
              variant: 'danger',
              name: 'calendar-overdue',
            });
          });
        });

        describe('when issue is closed', () => {
          it('does not render in red with overdue icon but shows "No start date" prefix', () => {
            wrapper = mountComponent({
              issue: object({ dueDate: '2020-01-01', state: STATUS_CLOSED }),
            });

            expect(findWorkItemAttribute().props('title')).toBe('No start date – Jan 1, 2020');
            expect(findDueDateIcon().props()).toMatchObject({
              variant: 'current',
              name: 'calendar',
            });
          });
        });
      });
    });

    describe('start date', () => {
      describe('with start date and due date', () => {
        it('renders date range', () => {
          wrapper = mountComponent({
            issue: workItemObject({ startDate: '2020-11-30', dueDate: '2020-12-12' }),
          });

          expect(findWorkItemAttribute().props('title')).toBe('Nov 30 – Dec 12, 2020');
        });
      });

      describe('with start date and no due date', () => {
        it('renders date range', () => {
          wrapper = mountComponent({
            issue: workItemObject({ startDate: '2020-11-30', dueDate: null }),
          });

          expect(findWorkItemAttribute().props('title')).toBe('Nov 30, 2020 – No due date');
        });
      });
    });

    describe('time estimate', () => {
      it('renders time estimate', () => {
        wrapper = mountComponent({ issue: object({ timeEstimate: '1w' }) });
        const timeEstimate = wrapper.findByTestId('time-estimate');

        expect(findWorkItemAttribute().props('title')).toBe('1w');
        expect(findWorkItemAttribute().props('tooltipText')).toBe('Estimate');
        expect(timeEstimate.findComponent(GlIcon).props('name')).toBe('timer');
      });
    });
  });

  describe('hiddenMetadataKeys', () => {
    it('hides multiple metadata fields', () => {
      wrapper = mountComponent({
        issue: issueObject({ dueDate: '2020-12-12' }),
        hiddenMetadataKeys: ['milestone', 'dates'],
      });

      expect(findMilestone().exists()).toBe(false);
      expect(findWorkItemAttribute().exists()).toBe(false);
    });

    it('handles undefined hiddenMetadataKeys', () => {
      wrapper = mountComponent({
        issue: issueObject({ dueDate: '2020-12-12' }),
        hiddenMetadataKeys: undefined,
      });

      expect(findMilestone().exists()).toBe(true);
      expect(findWorkItemAttribute().exists()).toBe(true);
    });
  });
});
