import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import IssueCardTimeInfo from '~/issues_list/components/issue_card_time_info.vue';

describe('IssuesListApp component', () => {
  useFakeDate(2020, 11, 11);

  let wrapper;

  const issue = {
    milestone: {
      dueDate: '2020-12-17',
      startDate: '2020-12-10',
      title: 'My milestone',
      webPath: '/milestone/webPath',
    },
    dueDate: '2020-12-12',
    humanTimeEstimate: '1w',
  };

  const findMilestone = () => wrapper.find('[data-testid="issuable-milestone"]');
  const findMilestoneTitle = () => findMilestone().find(GlLink).attributes('title');
  const findDueDate = () => wrapper.find('[data-testid="issuable-due-date"]');

  const mountComponent = ({
    dueDate = issue.dueDate,
    milestoneDueDate = issue.milestone.dueDate,
    milestoneStartDate = issue.milestone.startDate,
  } = {}) =>
    shallowMount(IssueCardTimeInfo, {
      propsData: {
        issue: {
          ...issue,
          milestone: {
            ...issue.milestone,
            dueDate: milestoneDueDate,
            startDate: milestoneStartDate,
          },
          dueDate,
        },
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('milestone', () => {
    it('renders', () => {
      wrapper = mountComponent();

      const milestone = findMilestone();

      expect(milestone.text()).toBe(issue.milestone.title);
      expect(milestone.find(GlIcon).props('name')).toBe('clock');
      expect(milestone.find(GlLink).attributes('href')).toBe(issue.milestone.webPath);
    });

    describe.each`
      time                         | text                   | milestoneDueDate | milestoneStartDate | expected
      ${'due date is in past'}     | ${'Past due'}          | ${'2020-09-09'}  | ${null}            | ${'Sep 9, 2020 (Past due)'}
      ${'due date is today'}       | ${'Today'}             | ${'2020-12-11'}  | ${null}            | ${'Dec 11, 2020 (Today)'}
      ${'start date is in future'} | ${'Upcoming'}          | ${'2021-03-01'}  | ${'2021-02-01'}    | ${'Mar 1, 2021 (Upcoming)'}
      ${'due date is in future'}   | ${'2 weeks remaining'} | ${'2020-12-25'}  | ${null}            | ${'Dec 25, 2020 (2 weeks remaining)'}
    `('when $description', ({ text, milestoneDueDate, milestoneStartDate, expected }) => {
      it(`renders with "${text}"`, () => {
        wrapper = mountComponent({ milestoneDueDate, milestoneStartDate });

        expect(findMilestoneTitle()).toBe(expected);
      });
    });
  });

  describe('due date', () => {
    describe('when upcoming', () => {
      it('renders', () => {
        wrapper = mountComponent();

        const dueDate = findDueDate();

        expect(dueDate.text()).toBe('Dec 12, 2020');
        expect(dueDate.attributes('title')).toBe('Due date');
        expect(dueDate.find(GlIcon).props('name')).toBe('calendar');
        expect(dueDate.classes()).not.toContain('gl-text-red-500');
      });
    });

    describe('when in the past', () => {
      it('renders in red', () => {
        wrapper = mountComponent({ dueDate: new Date('2020-10-10') });

        expect(findDueDate().classes()).toContain('gl-text-red-500');
      });
    });
  });

  it('renders time estimate', () => {
    wrapper = mountComponent();

    const timeEstimate = wrapper.find('[data-testid="time-estimate"]');

    expect(timeEstimate.text()).toBe(issue.humanTimeEstimate);
    expect(timeEstimate.attributes('title')).toBe('Estimate');
    expect(timeEstimate.find(GlIcon).props('name')).toBe('timer');
  });
});
