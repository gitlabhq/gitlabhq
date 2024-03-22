import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import IssueCardTimeInfo from '~/issues/list/components/issue_card_time_info.vue';
import { WIDGET_TYPE_MILESTONE, WIDGET_TYPE_START_AND_DUE_DATE } from '~/work_items/constants';

describe('CE IssueCardTimeInfo component', () => {
  useFakeDate(2020, 11, 11); // 2020 Dec 11

  let wrapper;

  const issueObject = {
    milestone: {
      dueDate: '2020-12-17',
      startDate: '2020-12-10',
      title: 'My milestone',
      webPath: '/milestone/webPath',
    },
    dueDate: '2020-12-12',
    humanTimeEstimate: '1w',
  };

  const workItemObject = {
    widgets: [
      {
        type: WIDGET_TYPE_MILESTONE,
        milestone: {
          dueDate: '2020-12-17',
          startDate: '2020-12-10',
          title: 'My milestone',
          webPath: '/milestone/webPath',
        },
      },
      {
        type: WIDGET_TYPE_START_AND_DUE_DATE,
        dueDate: '2020-12-12',
      },
    ],
  };

  const findMilestone = () => wrapper.find('[data-testid="issuable-milestone"]');
  const findMilestoneTitle = () => findMilestone().findComponent(GlLink).attributes('title');
  const findDueDate = () => wrapper.find('[data-testid="issuable-due-date"]');

  const mountComponent = ({
    issue = issueObject,
    state = STATUS_OPEN,
    dueDate = issueObject.dueDate,
    milestoneDueDate = issueObject.milestone.dueDate,
    milestoneStartDate = issueObject.milestone.startDate,
  } = {}) =>
    shallowMount(IssueCardTimeInfo, {
      propsData: {
        issue: {
          ...issue,
          milestone: {
            ...issueObject.milestone,
            dueDate: milestoneDueDate,
            startDate: milestoneStartDate,
          },
          state,
          dueDate,
        },
      },
    });

  describe.each`
    type           | obj
    ${'issue'}     | ${issueObject}
    ${'work item'} | ${workItemObject}
  `('with $type object', ({ obj }) => {
    describe('milestone', () => {
      it('renders', () => {
        wrapper = mountComponent({ issue: obj });

        const milestone = findMilestone();

        expect(milestone.text()).toBe('My milestone');
        expect(milestone.findComponent(GlIcon).props('name')).toBe('milestone');
        expect(milestone.findComponent(GlLink).attributes('href')).toBe('/milestone/webPath');
      });

      describe.each`
        time                         | text                   | milestoneDueDate | milestoneStartDate | expected
        ${'due date is in past'}     | ${'Past due'}          | ${'2020-09-09'}  | ${null}            | ${'Sep 9, 2020 (Past due)'}
        ${'due date is today'}       | ${'Today'}             | ${'2020-12-11'}  | ${null}            | ${'Dec 11, 2020 (Today)'}
        ${'start date is in future'} | ${'Upcoming'}          | ${'2021-03-01'}  | ${'2021-02-01'}    | ${'Mar 1, 2021 (Upcoming)'}
        ${'due date is in future'}   | ${'2 weeks remaining'} | ${'2020-12-25'}  | ${null}            | ${'Dec 25, 2020 (2 weeks remaining)'}
      `('when $description', ({ text, milestoneDueDate, milestoneStartDate, expected }) => {
        it(`renders with "${text}"`, () => {
          wrapper = mountComponent({ issue: obj, milestoneDueDate, milestoneStartDate });

          expect(findMilestoneTitle()).toBe(expected);
        });
      });
    });

    describe('due date', () => {
      describe('when upcoming', () => {
        it('renders', () => {
          wrapper = mountComponent({ issue: obj });

          const dueDate = findDueDate();

          expect(dueDate.text()).toBe('Dec 12, 2020');
          expect(dueDate.attributes('title')).toBe('Due date');
          expect(dueDate.findComponent(GlIcon).props('name')).toBe('calendar');
          expect(dueDate.classes()).not.toContain('gl-text-red-500');
        });
      });

      describe('when in the past', () => {
        describe('when issue is open', () => {
          it('renders in red', () => {
            wrapper = mountComponent({ issue: obj, dueDate: '2020-10-10' });

            expect(findDueDate().classes()).toContain('gl-text-red-500');
          });
        });

        describe('when issue is closed', () => {
          it('does not render in red', () => {
            wrapper = mountComponent({
              issue: obj,
              dueDate: '2020-10-10',
              state: STATUS_CLOSED,
            });

            expect(findDueDate().classes()).not.toContain('gl-text-red-500');
          });
        });
      });
    });
  });

  it('renders time estimate', () => {
    wrapper = mountComponent();

    const timeEstimate = wrapper.find('[data-testid="time-estimate"]');

    expect(timeEstimate.text()).toBe(issueObject.humanTimeEstimate);
    expect(timeEstimate.attributes('title')).toBe('Estimate');
    expect(timeEstimate.findComponent(GlIcon).props('name')).toBe('timer');
  });
});
