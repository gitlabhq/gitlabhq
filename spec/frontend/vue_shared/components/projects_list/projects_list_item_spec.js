import { GlAvatarLabeled, GlBadge, GlIcon, GlPopover } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  PROJECT_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { FEATURABLE_DISABLED, FEATURABLE_ENABLED } from '~/featurable/constants';

jest.mock('lodash/uniqueId', () => (prefix) => `${prefix}1`);

describe('ProjectsListItem', () => {
  let wrapper;

  const [project] = convertObjectPropsToCamelCase(projects, { deep: true });

  const defaultPropsData = { project };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(ProjectsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findIssuesLink = () => wrapper.findByRole('link', { name: ProjectsListItem.i18n.issues });
  const findForksLink = () => wrapper.findByRole('link', { name: ProjectsListItem.i18n.forks });
  const findProjectTopics = () => wrapper.findByTestId('project-topics');
  const findPopover = () => findProjectTopics().findComponent(GlPopover);

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
      size: '48',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]);
    expect(tooltip.value).toBe(PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]);
  });

  it('renders access role badge', () => {
    createComponent();

    expect(findAvatarLabeled().findComponent(UserAccessRoleBadge).text()).toBe(
      ACCESS_LEVEL_LABELS[project.permissions.projectAccess.accessLevel],
    );
  });

  describe('if project is archived', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          project: {
            ...project,
            archived: true,
          },
        },
      });
    });

    it('renders the archived badge', () => {
      expect(
        wrapper
          .findAllComponents(GlBadge)
          .wrappers.find((badge) => badge.text() === ProjectsListItem.i18n.archived),
      ).not.toBeUndefined();
    });
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
});
