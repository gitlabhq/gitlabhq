import { GlSprintf, GlLabel, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import Issuable from '~/issues_list/components/issuable.vue';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import initUserPopovers from '~/user_popovers';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import { simpleIssue, testAssignees, testLabels } from '../issuable_list_test_data';

jest.mock('~/user_popovers');

const TODAY = new Date();

const createTestDateFromDelta = (timeDelta) =>
  formatDate(new Date(TODAY.getTime() + timeDelta), 'yyyy-mm-dd');

// TODO: Encapsulate date helpers https://gitlab.com/gitlab-org/gitlab/-/issues/320883
const MONTHS_IN_MS = 1000 * 60 * 60 * 24 * 31;
const TEST_MONTH_AGO = createTestDateFromDelta(-MONTHS_IN_MS);
const TEST_MONTH_LATER = createTestDateFromDelta(MONTHS_IN_MS);
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
const MOCK_GITLAB_URL = 'http://0.0.0.0:3000';

describe('Issuable component', () => {
  let issuable;
  let wrapper;

  const factory = (props = {}, scopedLabelsAvailable = false) => {
    wrapper = shallowMount(Issuable, {
      propsData: {
        issuable: simpleIssue,
        baseUrl: TEST_BASE_URL,
        ...props,
      },
      provide: {
        scopedLabelsAvailable,
      },
      stubs: {
        'gl-sprintf': GlSprintf,
      },
    });
  };

  beforeEach(() => {
    issuable = { ...simpleIssue };
    gon.gitlab_url = MOCK_GITLAB_URL;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const checkExists = (findFn) => () => findFn().exists();
  const hasIcon = (iconName, iconWrapper = wrapper) =>
    iconWrapper.findAll(GlIcon).wrappers.some((icon) => icon.props('name') === iconName);
  const hasConfidentialIcon = () => hasIcon('eye-slash');
  const findTaskStatus = () => wrapper.find('.task-status');
  const findOpenedAgoContainer = () => wrapper.find('[data-testid="openedByMessage"]');
  const findAuthor = () => wrapper.find({ ref: 'openedAgoByContainer' });
  const findMilestone = () => wrapper.find('.js-milestone');
  const findMilestoneTooltip = () => findMilestone().attributes('title');
  const findDueDate = () => wrapper.find('.js-due-date');
  const findLabels = () => wrapper.findAll(GlLabel);
  const findWeight = () => wrapper.find('[data-testid="weight"]');
  const findAssignees = () => wrapper.find(IssueAssignees);
  const findBlockingIssuesCount = () => wrapper.find('[data-testid="blocking-issues"]');
  const findMergeRequestsCount = () => wrapper.find('[data-testid="merge-requests"]');
  const findUpvotes = () => wrapper.find('[data-testid="upvotes"]');
  const findDownvotes = () => wrapper.find('[data-testid="downvotes"]');
  const findNotes = () => wrapper.find('[data-testid="notes-count"]');
  const findBulkCheckbox = () => wrapper.find('input.selected-issuable');
  const findScopedLabels = () => findLabels().filter((w) => isScopedLabel({ title: w.text() }));
  const findUnscopedLabels = () => findLabels().filter((w) => !isScopedLabel({ title: w.text() }));
  const findIssuableTitle = () => wrapper.find('[data-testid="issuable-title"]');
  const findIssuableStatus = () => wrapper.find('[data-testid="issuable-status"]');
  const containsJiraLogo = () => wrapper.find('[data-testid="jira-logo"]').exists();
  const findHealthStatus = () => wrapper.find('.health-status');

  describe('when mounted', () => {
    it('initializes user popovers', () => {
      expect(initUserPopovers).not.toHaveBeenCalled();

      factory();

      expect(initUserPopovers).toHaveBeenCalledWith([wrapper.vm.$refs.openedAgoByContainer.$el]);
    });
  });

  describe('when scopedLabels feature is available', () => {
    beforeEach(() => {
      issuable.labels = [...testLabels];

      factory({ issuable }, true);
    });

    describe('when label is scoped', () => {
      it('returns label with correct props', () => {
        const scopedLabel = findScopedLabels().at(0);

        expect(scopedLabel.props('scoped')).toBe(true);
      });
    });

    describe('when label is not scoped', () => {
      it('returns label with correct props', () => {
        const notScopedLabel = findUnscopedLabels().at(0);

        expect(notScopedLabel.props('scoped')).toBe(false);
      });
    });
  });

  describe('when scopedLabels feature is not available', () => {
    beforeEach(() => {
      issuable.labels = [...testLabels];

      factory({ issuable });
    });

    describe('when label is scoped', () => {
      it('label scoped props is false', () => {
        const scopedLabel = findScopedLabels().at(0);

        expect(scopedLabel.props('scoped')).toBe(false);
      });
    });

    describe('when label is not scoped', () => {
      it('label scoped props is false', () => {
        const notScopedLabel = findUnscopedLabels().at(0);

        expect(notScopedLabel.props('scoped')).toBe(false);
      });
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
      desc                       | check
      ${'bulk editing checkbox'} | ${checkExists(findBulkCheckbox)}
      ${'confidential icon'}     | ${hasConfidentialIcon}
      ${'task status'}           | ${checkExists(findTaskStatus)}
      ${'milestone'}             | ${checkExists(findMilestone)}
      ${'due date'}              | ${checkExists(findDueDate)}
      ${'labels'}                | ${checkExists(findLabels)}
      ${'weight'}                | ${checkExists(findWeight)}
      ${'blocking issues count'} | ${checkExists(findBlockingIssuesCount)}
      ${'merge request count'}   | ${checkExists(findMergeRequestsCount)}
      ${'upvotes'}               | ${checkExists(findUpvotes)}
      ${'downvotes'}             | ${checkExists(findDownvotes)}
    `('does not render $desc', ({ check }) => {
      expect(check()).toBe(false);
    });

    it('show relative reference path', () => {
      expect(wrapper.find('.js-ref-path').text()).toBe(issuable.references.relative);
    });

    it('does not have closed text', () => {
      expect(wrapper.text()).not.toContain(TEXT_CLOSED);
    });

    it('does not have closed class', () => {
      expect(wrapper.classes('closed')).toBe(false);
    });

    it('renders fuzzy created date and author', () => {
      expect(trimText(findOpenedAgoContainer().text())).toContain(
        `created 1 month ago by ${TEST_USER_NAME}`,
      );
    });

    it('renders no comments', () => {
      expect(findNotes().classes('no-comments')).toBe(true);
    });

    it.each`
      gitlabWebUrl           | webUrl                        | expectedHref                  | expectedTarget | isExternal
      ${undefined}           | ${`${MOCK_GITLAB_URL}/issue`} | ${`${MOCK_GITLAB_URL}/issue`} | ${undefined}   | ${false}
      ${undefined}           | ${'https://jira.com/issue'}   | ${'https://jira.com/issue'}   | ${'_blank'}    | ${true}
      ${'/gitlab-org/issue'} | ${'https://jira.com/issue'}   | ${'/gitlab-org/issue'}        | ${undefined}   | ${false}
    `(
      'renders issuable title correctly when `gitlabWebUrl` is `$gitlabWebUrl` and webUrl is `$webUrl`',
      async ({ webUrl, gitlabWebUrl, expectedHref, expectedTarget, isExternal }) => {
        factory({
          issuable: {
            ...issuable,
            web_url: webUrl,
            gitlab_web_url: gitlabWebUrl,
          },
        });

        const titleEl = findIssuableTitle();

        expect(titleEl.exists()).toBe(true);
        expect(titleEl.find(GlLink).attributes('href')).toBe(expectedHref);
        expect(titleEl.find(GlLink).attributes('target')).toBe(expectedTarget);
        expect(titleEl.find(GlLink).text()).toBe(issuable.title);

        expect(titleEl.find(GlIcon).exists()).toBe(isExternal);
      },
    );
  });

  describe('with confidential issuable', () => {
    beforeEach(() => {
      issuable.confidential = true;

      factory({ issuable });
    });

    it('renders the confidential icon', () => {
      expect(hasConfidentialIcon()).toBe(true);
    });
  });

  describe('with Jira issuable', () => {
    beforeEach(() => {
      issuable.external_tracker = 'jira';

      factory({ issuable });
    });

    it('renders the Jira icon', () => {
      expect(containsJiraLogo()).toBe(true);
    });

    it('opens issuable in a new tab', () => {
      expect(findIssuableTitle().props('target')).toBe('_blank');
    });

    it('opens author in a new tab', () => {
      expect(findAuthor().props('target')).toBe('_blank');
    });

    describe('with Jira status', () => {
      const expectedStatus = 'In Progress';

      beforeEach(() => {
        issuable.status = expectedStatus;

        factory({ issuable });
      });

      it('renders the Jira status', () => {
        expect(findIssuableStatus().text()).toBe(expectedStatus);
      });
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
      expect(hasIcon('clock', findMilestone())).toBe(true);
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

      const labels = findLabels().wrappers.map((label) => ({
        href: label.props('target'),
        text: label.text(),
        tooltip: label.attributes('description'),
      }));

      const expected = testLabels.map((label) => ({
        href: mergeUrlParams({ 'label_name[]': label.name }, TEST_BASE_URL),
        text: label.name,
        tooltip: label.description,
      }));

      expect(labels).toEqual(expected);
    });
  });

  describe('with labels for Jira issuable', () => {
    beforeEach(() => {
      issuable.labels = [...testLabels];
      issuable.external_tracker = 'jira';

      factory({ issuable });
    });

    it('renders labels', () => {
      factory({ issuable });

      const labels = findLabels().wrappers.map((label) => ({
        href: label.props('target'),
        text: label.text(),
        tooltip: label.attributes('description'),
      }));

      const expected = testLabels.map((label) => ({
        href: mergeUrlParams({ 'labels[]': label.name }, TEST_BASE_URL),
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
    desc                            | key                        | finder
    ${'with blocking issues count'} | ${'blocking_issues_count'} | ${findBlockingIssuesCount}
    ${'with merge requests count'}  | ${'merge_requests_count'}  | ${findMergeRequestsCount}
    ${'with upvote count'}          | ${'upvotes'}               | ${findUpvotes}
    ${'with downvote count'}        | ${'downvotes'}             | ${findDownvotes}
    ${'with notes count'}           | ${'user_notes_count'}      | ${findNotes}
  `('$desc', ({ key, finder }) => {
    beforeEach(() => {
      issuable[key] = TEST_META_COUNT;

      factory({ issuable });
    });

    it('renders correct count', () => {
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

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.emitted().select).toEqual([[{ issuable, selected: !selected }]]);
        });
      });
    });
  });

  if (IS_EE) {
    describe('with health status', () => {
      it('renders health status tag', () => {
        factory({ issuable });
        expect(findHealthStatus().exists()).toBe(true);
      });

      it('does not render when health status is absent', () => {
        issuable.health_status = null;
        factory({ issuable });
        expect(findHealthStatus().exists()).toBe(false);
      });
    });
  }
});
