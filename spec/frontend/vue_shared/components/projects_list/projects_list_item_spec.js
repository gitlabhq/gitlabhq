import { GlAvatarLabeled, GlBadge, GlIcon, GlPopover } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import projects from 'test_fixtures/api/users/projects/get.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectListItemInactiveBadge from 'ee_else_ce/vue_shared/components/projects_list/project_list_item_inactive_badge.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  PROJECT_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_DISABLED, FEATURABLE_ENABLED } from '~/featurable/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';

jest.mock('lodash/uniqueId');

describe('ProjectsListItem', () => {
  let wrapper;

  const [{ permissions, ...project }] = convertObjectPropsToCamelCase(projects, { deep: true });

  const defaultPropsData = {
    project: {
      ...project,
      accessLevel: {
        integerValue: permissions.projectAccess.accessLevel,
      },
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(ProjectsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findMergeRequestsLink = () =>
    wrapper.findByRole('link', { name: ProjectsListItem.i18n.mergeRequests });
  const findIssuesLink = () => wrapper.findByRole('link', { name: ProjectsListItem.i18n.issues });
  const findForksLink = () => wrapper.findByRole('link', { name: ProjectsListItem.i18n.forks });
  const findProjectTopics = () => wrapper.findByTestId('project-topics');
  const findPopover = () => findProjectTopics().findComponent(GlPopover);
  const findProjectDescription = () => wrapper.findByTestId('project-description');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);
  const findListActions = () => wrapper.findComponent(ListActions);
  const findAccessLevelBadge = () => wrapper.findByTestId('access-level-badge');
  const findInactiveBadge = () => wrapper.findComponent(ProjectListItemInactiveBadge);

  beforeEach(() => {
    uniqueId.mockImplementation(jest.requireActual('lodash/uniqueId'));
  });

  it('renders project avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: project.name,
      labelLink: project.webUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': project.id.toString(),
      'entity-name': project.name,
      shape: 'rect',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]);
    expect(tooltip.value).toBe(PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]);
  });

  describe('when visibility is not provided', () => {
    it('does not render visibility icon', () => {
      const { visibility, ...projectWithoutVisibility } = project;
      createComponent({
        propsData: {
          project: projectWithoutVisibility,
        },
      });

      expect(findVisibilityIcon().exists()).toBe(false);
    });
  });

  it('renders access level badge', () => {
    createComponent();

    expect(findAccessLevelBadge().text()).toBe(
      ACCESS_LEVEL_LABELS[defaultPropsData.project.accessLevel.integerValue],
    );
  });

  describe('when access level is not available', () => {
    beforeEach(() => {
      createComponent({
        propsData: { project },
      });
    });

    it('does not render access level badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  describe('when access level is `No access`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          project: { ...project, accessLevel: { integerValue: ACCESS_LEVEL_NO_ACCESS_INTEGER } },
        },
      });
    });

    it('does not render access level badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  it('renders inactive badge', () => {
    createComponent();

    expect(findInactiveBadge().exists()).toBe(true);
  });

  it('renders stars count', () => {
    createComponent();

    const starsLink = wrapper.findByRole('link', { name: ProjectsListItem.i18n.stars });
    const tooltip = getBinding(starsLink.element, 'gl-tooltip');

    expect(tooltip.value).toBe(ProjectsListItem.i18n.stars);
    expect(starsLink.attributes('href')).toBe(`${project.webUrl}/-/starrers`);
    expect(starsLink.text()).toBe(project.starCount.toString());
    expect(starsLink.findComponent(GlIcon).props('name')).toBe('star-o');
  });

  it('renders updated at', () => {
    createComponent();

    expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(project.updatedAt);
  });

  describe('when updated at is not available', () => {
    it('does not render updated at', () => {
      const { updatedAt, ...projectWithoutUpdatedAt } = project;
      createComponent({
        propsData: {
          project: projectWithoutUpdatedAt,
        },
      });

      expect(wrapper.findComponent(TimeAgoTooltip).exists()).toBe(false);
    });
  });

  describe('when merge requests are enabled', () => {
    it('renders merge requests count', () => {
      createComponent({
        propsData: {
          project: {
            ...project,
            openMergeRequestsCount: 5,
          },
        },
      });

      const mergeRequestsLink = findMergeRequestsLink();
      const tooltip = getBinding(mergeRequestsLink.element, 'gl-tooltip');

      expect(tooltip.value).toBe(ProjectsListItem.i18n.mergeRequests);
      expect(mergeRequestsLink.attributes('href')).toBe(`${project.webUrl}/-/merge_requests`);
      expect(mergeRequestsLink.text()).toBe('5');
      expect(mergeRequestsLink.findComponent(GlIcon).props('name')).toBe('git-merge');
    });
  });

  describe('when merge requests are not enabled', () => {
    it('does not render merge requests count', () => {
      createComponent({
        propsData: {
          project: {
            ...project,
            mergeRequestsAccessLevel: FEATURABLE_DISABLED,
          },
        },
      });

      expect(findMergeRequestsLink().exists()).toBe(false);
    });
  });

  describe('when issues are enabled', () => {
    it('renders issues count', () => {
      createComponent();

      const issuesLink = findIssuesLink();
      const tooltip = getBinding(issuesLink.element, 'gl-tooltip');

      expect(tooltip.value).toBe(ProjectsListItem.i18n.issues);
      expect(issuesLink.attributes('href')).toBe(`${project.webUrl}/-/issues`);
      expect(issuesLink.text()).toBe(project.openIssuesCount.toString());
      expect(issuesLink.findComponent(GlIcon).props('name')).toBe('issues');
    });
  });

  describe('when issues are not enabled', () => {
    it('does not render issues count', () => {
      createComponent({
        propsData: {
          project: {
            ...project,
            issuesAccessLevel: FEATURABLE_DISABLED,
          },
        },
      });

      expect(findIssuesLink().exists()).toBe(false);
    });
  });

  describe('when forking is enabled', () => {
    it('renders forks count', () => {
      createComponent();

      const forksLink = findForksLink();
      const tooltip = getBinding(forksLink.element, 'gl-tooltip');

      expect(tooltip.value).toBe(ProjectsListItem.i18n.forks);
      expect(forksLink.attributes('href')).toBe(`${project.webUrl}/-/forks`);
      expect(forksLink.text()).toBe(project.openIssuesCount.toString());
      expect(forksLink.findComponent(GlIcon).props('name')).toBe('fork');
    });
  });

  describe('when forking is not enabled', () => {
    it.each([
      {
        ...project,
        forksCount: 2,
        forkingAccessLevel: FEATURABLE_DISABLED,
      },
      {
        ...project,
        forksCount: undefined,
        forkingAccessLevel: FEATURABLE_ENABLED,
      },
    ])('does not render forks count', (modifiedProject) => {
      createComponent({
        propsData: {
          project: modifiedProject,
        },
      });

      expect(findForksLink().exists()).toBe(false);
    });
  });

  describe('if project has topics', () => {
    beforeEach(() => {
      uniqueId.mockImplementation((prefix) => `${prefix}1`);
    });

    it('renders first three topics', () => {
      createComponent();

      const firstThreeTopics = project.topics.slice(0, 3);
      const firstThreeBadges = findProjectTopics().findAllComponents(GlBadge).wrappers.slice(0, 3);
      const firstThreeBadgesText = firstThreeBadges.map((badge) => badge.text());
      const firstThreeBadgesHref = firstThreeBadges.map((badge) => badge.attributes('href'));

      expect(firstThreeTopics).toEqual(firstThreeBadgesText);
      expect(firstThreeBadgesHref).toEqual(
        firstThreeTopics.map((topic) => `/explore/projects/topics/${encodeURIComponent(topic)}`),
      );
    });

    it('renders the rest of the topics in a popover', () => {
      createComponent();

      const topics = project.topics.slice(3);
      const badges = findPopover().findAllComponents(GlBadge).wrappers;
      const badgesText = badges.map((badge) => badge.text());
      const badgesHref = badges.map((badge) => badge.attributes('href'));

      expect(topics).toEqual(badgesText);
      expect(badgesHref).toEqual(
        topics.map((topic) => `/explore/projects/topics/${encodeURIComponent(topic)}`),
      );
    });

    it('renders button to open popover', () => {
      createComponent();

      const expectedButtonId = 'project-topics-popover-1';

      expect(wrapper.findByText('+ 2 more').attributes('id')).toBe(expectedButtonId);
      expect(findPopover().props('target')).toBe(expectedButtonId);
    });

    describe('when topic has a name longer than 15 characters', () => {
      it('truncates name and shows tooltip with full name', () => {
        const topicWithLongName = 'topic with very very very long name';

        createComponent({
          propsData: {
            project: {
              ...project,
              topics: [topicWithLongName, ...project.topics],
            },
          },
        });

        const firstTopicBadge = findProjectTopics().findComponent(GlBadge);
        const tooltip = getBinding(firstTopicBadge.element, 'gl-tooltip');

        expect(firstTopicBadge.text()).toBe('topic with ver…');
        expect(tooltip.value).toBe(topicWithLongName);
      });
    });
  });

  describe('when project has a description', () => {
    it('renders description', () => {
      const descriptionHtml = '<p>Foo bar</p>';

      createComponent({
        propsData: {
          project: {
            ...project,
            descriptionHtml,
          },
        },
      });

      expect(findProjectDescription().element.innerHTML).toBe(descriptionHtml);
    });
  });

  describe('when project does not have a description', () => {
    it('does not render description', () => {
      createComponent();

      expect(findProjectDescription().exists()).toBe(false);
    });
  });

  describe('when `showProjectIcon` prop is `true`', () => {
    it('shows project icon', () => {
      createComponent({ propsData: { showProjectIcon: true } });

      expect(wrapper.findByTestId('project-icon').exists()).toBe(true);
    });
  });

  describe('when `showProjectIcon` prop is `false`', () => {
    it('does not show project icon', () => {
      createComponent();

      expect(wrapper.findByTestId('project-icon').exists()).toBe(false);
    });
  });

  describe('when project has actions', () => {
    const editPath = '/foo/bar/edit';

    beforeEach(() => {
      createComponent({
        propsData: {
          project: {
            ...project,
            availableActions: [ACTION_EDIT, ACTION_DELETE],
            actionLoadingStates: { [ACTION_DELETE]: false },
            isForked: true,
            editPath,
          },
        },
      });
    });

    it('displays actions dropdown', () => {
      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_EDIT]: {
            href: editPath,
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_EDIT, ACTION_DELETE],
      });
    });

    describe('when delete action is fired', () => {
      beforeEach(() => {
        findListActions().props('actions')[ACTION_DELETE].action();
      });

      it('displays confirmation modal with correct props', () => {
        expect(wrapper.findComponent(DeleteModal).props()).toMatchObject({
          visible: true,
          confirmPhrase: project.name,
          isFork: true,
          issuesCount: '0',
          forksCount: '0',
          starsCount: '0',
          confirmLoading: false,
        });
      });

      describe('when deletion is confirmed', () => {
        beforeEach(() => {
          wrapper.findComponent(DeleteModal).vm.$emit('primary');
        });

        it('emits `delete` event', () => {
          expect(wrapper.emitted('delete')).toMatchObject([[project]]);
        });
      });
    });
  });
});
