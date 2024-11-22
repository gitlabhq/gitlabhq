import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import { STATUS_CLOSED } from '~/issues/constants';
import IssueCardTimeInfo from '~/issues/list/components/issue_card_time_info.vue';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import { WIDGET_TYPE_MILESTONE, WIDGET_TYPE_START_AND_DUE_DATE } from '~/work_items/constants';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('CE IssueCardTimeInfo component', () => {
  useFakeDate(2020, 11, 11); // 2020 Dec 11

  let wrapper;

  const issueObject = ({ milestoneStartDate, milestoneDueDate, dueDate, state } = {}) => ({
    milestone: {
      dueDate: milestoneDueDate,
      startDate: milestoneStartDate,
      title: 'My milestone',
      webPath: '/milestone/webPath',
    },
    dueDate,
    humanTimeEstimate: '1w',
    state,
  });

  const workItemObject = ({
    milestoneStartDate,
    milestoneDueDate,
    startDate,
    dueDate,
    state,
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
    ],
  });

  const findMilestone = () => wrapper.findComponent(IssuableMilestone);
  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);

  const mountComponent = ({ issue = issueObject() } = {}) =>
    shallowMount(IssueCardTimeInfo, {
      propsData: { issue },
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
    });

    describe('due date', () => {
      describe('when upcoming', () => {
        it('renders', () => {
          wrapper = mountComponent({ issue: object({ dueDate: '2020-12-12' }) });
          expect(findWorkItemAttribute().props('title')).toBe('Dec 12, 2020');
          expect(findWorkItemAttribute().props('tooltipText')).toBe('Due date');
          const datesEl = wrapper.find('[data-testid="issuable-due-date"]');
          expect(datesEl.findComponent(GlIcon).props()).toMatchObject({
            variant: 'current',
            name: 'calendar',
          });
        });
      });

      describe('when in the past', () => {
        describe('when issue is open', () => {
          it('renders in red with overdue icon', () => {
            wrapper = mountComponent({ issue: object({ dueDate: '2020-10-10' }) });
            const datesEl = wrapper.find('[data-testid="issuable-due-date"]');
            expect(datesEl.findComponent(GlIcon).props()).toMatchObject({
              variant: 'danger',
              name: 'calendar-overdue',
            });
          });
        });

        describe('when issue is closed', () => {
          it('does not render in red with overdue icon', () => {
            wrapper = mountComponent({
              issue: object({ dueDate: '2020-10-10', state: STATUS_CLOSED }),
            });

            const datesEl = wrapper.find('[data-testid="issuable-due-date"]');
            expect(datesEl.findComponent(GlIcon).props()).toMatchObject({
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
  });

  it('renders time estimate', () => {
    wrapper = mountComponent();
    const timeEstimate = wrapper.find('[data-testid="time-estimate"]');

    expect(findWorkItemAttribute().props('title')).toBe('1w');
    expect(findWorkItemAttribute().props('tooltipText')).toBe('Estimate');
    expect(timeEstimate.findComponent(GlIcon).props('name')).toBe('timer');
  });
});
