import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import initUserPopovers from '~/user_popovers';
import { formatDate } from '~/lib/utils/datetime_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import Issuable from '~/issuables_list/components/issuable.vue';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import { simpleIssue, testAssignees, testLabels } from '../issuable_list_test_data';

jest.mock('~/user_popovers');

const TEST_NOW = '2019-08-28T20:03:04.713Z';
const TEST_MONTH_AGO = '2019-07-28';
const TEST_MONTH_LATER = '2019-09-30';
const DATE_FORMAT = 'mmm d, yyyy';
const TEST_USER_NAME = 'Tyler Durden';
const TEST_BASE_URL = `${TEST_HOST}/issues`;
const TEST_TASK_STATUS = '50 of 100 tasks completed';
const TEST_MILESTONE = {
  title: 'Milestone title',
  web_url: `${TEST_HOST}/milestone/1`,
};
const TEXT_CLOSED = 'CLOSED';
const TEST_META_COUNT = 100;

// Use FixedDate so that time sensitive info in snapshots don't fail
class FixedDate extends Date {
  constructor(date = TEST_NOW) {
    super(date);
  }
}

describe('Issuable component', () => {
  let issuable;
  let DateOrig;
  let wrapper;

  const factory = (props = {}) => {
    wrapper = shallowMount(Issuable, {
      propsData: {
        issuable: simpleIssue,
        baseUrl: TEST_BASE_URL,
        ...props,
      },
      sync: false,
      attachToDocument: true,
    });
  };

  beforeEach(() => {
    issuable = { ...simpleIssue };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  beforeAll(() => {
    DateOrig = window.Date;
    window.Date = FixedDate;
  });

  afterAll(() => {
    window.Date = DateOrig;
  });

  const findConfidentialIcon = () => wrapper.find('.fa-eye-slash');
  const findTaskStatus = () => wrapper.find('.task-status');
  const findOpenedAgoContainer = () => wrapper.find({ ref: 'openedAgoByContainer' });
  const findMilestone = () => wrapper.find('.js-milestone');
  const findMilestoneTooltip = () => findMilestone().attributes('data-original-title');
  const findDueDate = () => wrapper.find('.js-due-date');
  const findLabelContainer = () => wrapper.find('.js-labels');
  const findLabelLinks = () => findLabelContainer().findAll(GlLink);
  const findWeight = () => wrapper.find('.js-weight');
  const findAssignees = () => wrapper.find(IssueAssignees);
  const findMergeRequestsCount = () => wrapper.find('.js-merge-requests');
  const findUpvotes = () => wrapper.find('.js-upvotes');
  const findDownvotes = () => wrapper.find('.js-downvotes');
  const findNotes = () => wrapper.find('.js-notes');
  const findBulkCheckbox = () => wrapper.find('input.selected-issuable');

  describe('when mounted', () => {
    it('initializes user popovers', () => {
      expect(initUserPopovers).not.toHaveBeenCalled();

      factory();

      expect(initUserPopovers).toHaveBeenCalledWith([findOpenedAgoContainer().find('a').element]);
    });
  });

  describe('with simple issuable', () => {
    beforeEach(() => {
      Object.assign(issuable, {
        has_tasks: false,
        task_status: TEST_TASK_STATUS,
        created_at: TEST_MONTH_AGO,
        author: {
          ...issuable.author,
          name: TEST_USER_NAME,
        },
        labels: [],
      });

      factory({ issuable });
    });

    it.each`
      desc                       | finder
      ${'bulk editing checkbox'} | ${findBulkCheckbox}
      ${'confidential icon'}     | ${findConfidentialIcon}
      ${'task status'}           | ${findTaskStatus}
      ${'milestone'}             | ${findMilestone}
      ${'due date'}              | ${findDueDate}
      ${'labels'}                | ${findLabelContainer}
      ${'weight'}                | ${findWeight}
      ${'merge request count'}   | ${findMergeRequestsCount}
      ${'upvotes'}               | ${findUpvotes}
      ${'downvotes'}             | ${findDownvotes}
    `('does not render $desc', ({ finder }) => {
      expect(finder().exists()).toBe(false);
    });

    it('does not have closed text', () => {
      expect(wrapper.text()).not.toContain(TEXT_CLOSED);
    });

    it('does not have closed class', () => {
      expect(wrapper.classes('closed')).toBe(false);
    });

    it('renders fuzzy opened date and author', () => {
      expect(trimText(findOpenedAgoContainer().text())).toEqual(
        `opened 1 month ago by ${TEST_USER_NAME}`,
      );
    });

    it('renders no comments', () => {
      expect(findNotes().classes('no-comments')).toBe(true);
    });
  });

  describe('with confidential issuable', () => {
    beforeEach(() => {
      issuable.confidential = true;

      factory({ issuable });
    });

    it('renders the confidential icon', () => {
      expect(findConfidentialIcon().exists()).toBe(true);
    });
  });

  describe('with task status', () => {
    beforeEach(() => {
      Object.assign(issuable, {
        has_tasks: true,
        task_status: TEST_TASK_STATUS,
      });

      factory({ issuable });
    });

    it('renders task status', () => {
      expect(findTaskStatus().exists()).toBe(true);
      expect(findTaskStatus().text()).toBe(TEST_TASK_STATUS);
    });
  });

  describe.each`
    desc            | dueDate             | expectedTooltipPart
    ${'past due'}   | ${TEST_MONTH_AGO}   | ${'Past due'}
    ${'future due'} | ${TEST_MONTH_LATER} | ${'1 month remaining'}
  `('with milestone with $desc', ({ dueDate, expectedTooltipPart }) => {
    beforeEach(() => {
      issuable.milestone = { ...TEST_MILESTONE, due_date: dueDate };

      factory({ issuable });
    });

    it('renders milestone', () => {
      expect(findMilestone().exists()).toBe(true);
      expect(
        findMilestone()
          .find('.fa-clock-o')
          .exists(),
      ).toBe(true);
      expect(findMilestone().text()).toEqual(TEST_MILESTONE.title);
    });

    it('renders tooltip', () => {
      expect(findMilestoneTooltip()).toBe(
        `${formatDate(dueDate, DATE_FORMAT)} (${expectedTooltipPart})`,
      );
    });

    it('renders milestone with the correct href', () => {
      const { title } = issuable.milestone;
      const expected = mergeUrlParams({ milestone_title: title }, TEST_BASE_URL);

      expect(findMilestone().attributes('href')).toBe(expected);
    });
  });

  describe.each`
    dueDate             | hasClass | desc
    ${TEST_MONTH_LATER} | ${false} | ${'with future due date'}
    ${TEST_MONTH_AGO}   | ${true}  | ${'with past due date'}
  `('$desc', ({ dueDate, hasClass }) => {
    beforeEach(() => {
      issuable.due_date = dueDate;

      factory({ issuable });
    });

    it('renders due date', () => {
      expect(findDueDate().exists()).toBe(true);
      expect(findDueDate().text()).toBe(formatDate(dueDate, DATE_FORMAT));
    });

    it(hasClass ? 'has cred class' : 'does not have cred class', () => {
      expect(findDueDate().classes('cred')).toEqual(hasClass);
    });
  });

  describe('with labels', () => {
    beforeEach(() => {
      issuable.labels = [...testLabels];

      factory({ issuable });
    });

    it('renders labels', () => {
      factory({ issuable });

      const labels = findLabelLinks().wrappers.map(label => ({
        href: label.attributes('href'),
        text: label.text(),
        tooltip: label.find('span').attributes('data-original-title'),
      }));

      const expected = testLabels.map(label => ({
        href: mergeUrlParams({ 'label_name[]': label.name }, TEST_BASE_URL),
        text: label.name,
        tooltip: label.description,
      }));

      expect(labels).toEqual(expected);
    });
  });

  describe.each`
    weight
    ${0}
    ${10}
    ${12345}
  `('with weight $weight', ({ weight }) => {
    beforeEach(() => {
      issuable.weight = weight;

      factory({ issuable });
    });

    it('renders weight', () => {
      expect(findWeight().exists()).toBe(true);
      expect(findWeight().text()).toEqual(weight.toString());
    });
  });

  describe('with closed state', () => {
    beforeEach(() => {
      issuable.state = 'closed';

      factory({ issuable });
    });

    it('renders closed text', () => {
      expect(wrapper.text()).toContain(TEXT_CLOSED);
    });

    it('has closed class', () => {
      expect(wrapper.classes('closed')).toBe(true);
    });
  });

  describe('with assignees', () => {
    beforeEach(() => {
      issuable.assignees = testAssignees;

      factory({ issuable });
    });

    it('renders assignees', () => {
      expect(findAssignees().exists()).toBe(true);
      expect(findAssignees().props('assignees')).toEqual(testAssignees);
    });
  });

  describe.each`
    desc                           | key                       | finder
    ${'with merge requests count'} | ${'merge_requests_count'} | ${findMergeRequestsCount}
    ${'with upvote count'}         | ${'upvotes'}              | ${findUpvotes}
    ${'with downvote count'}       | ${'downvotes'}            | ${findDownvotes}
    ${'with notes count'}          | ${'user_notes_count'}     | ${findNotes}
  `('$desc', ({ key, finder }) => {
    beforeEach(() => {
      issuable[key] = TEST_META_COUNT;

      factory({ issuable });
    });

    it('renders merge requests count', () => {
      expect(finder().exists()).toBe(true);
      expect(finder().text()).toBe(TEST_META_COUNT.toString());
      expect(finder().classes('no-comments')).toBe(false);
    });
  });

  describe('with bulk editing', () => {
    describe.each`
      selected | desc
      ${true}  | ${'when selected'}
      ${false} | ${'when unselected'}
    `('$desc', ({ selected }) => {
      beforeEach(() => {
        factory({ isBulkEditing: true, selected });
      });

      it(`renders checked is ${selected}`, () => {
        expect(findBulkCheckbox().element.checked).toBe(selected);
      });

      it('emits select when clicked', () => {
        expect(wrapper.emitted().select).toBeUndefined();

        findBulkCheckbox().trigger('click');

        expect(wrapper.emitted().select).toEqual([[{ issuable, selected: !selected }]]);
      });
    });
  });
});
