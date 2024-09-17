import { nextTick } from 'vue';
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
import waitForPromises from 'helpers/wait_for_promises';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  PROJECT_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_DISABLED, FEATURABLE_ENABLED } from '~/featurable/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import {
  renderDeleteSuccessToast,
  deleteParams,
} from 'ee_else_ce/vue_shared/components/resource_lists/utils';
import { deleteProject } from '~/api/projects_api';
import { createAlert } from '~/alert';

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

jest.mock('lodash/uniqueId');
jest.mock('ee_else_ce/vue_shared/components/resource_lists/utils', () => ({
  ...jest.requireActual('ee_else_ce/vue_shared/components/resource_lists/utils'),
  renderDeleteSuccessToast: jest.fn(),
  deleteParams: jest.fn(() => MOCK_DELETE_PARAMS),
}));
jest.mock('~/alert');
jest.mock('~/api/projects_api');

describe('ProjectsListItem', () => {
  let wrapper;

  const [{ permissions, ...project }] = convertObjectPropsToCamelCase(projects, { deep: true });

  const defaultPropsData = {
    project: {
      ...project,
      accessLevel: {
        integerValue: permissions.projectAccess.accessLevel,
      },
      avatarUrl: 'avatar.jpg',
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
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const deleteModalFirePrimaryEvent = async () => {
    findDeleteModal().vm.$emit('primary');
    await nextTick();
  };

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
      src: defaultPropsData.project.avatarUrl,
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

  describe.each`
    timestampType                | expectedText | expectedTimeProp
    ${TIMESTAMP_TYPE_CREATED_AT} | ${'Created'} | ${project.createdAt}
    ${TIMESTAMP_TYPE_UPDATED_AT} | ${'Updated'} | ${project.updatedAt}
    ${undefined}                 | ${'Created'} | ${project.createdAt}
  `(
    'when `timestampType` prop is $timestampType',
    ({ timestampType, expectedText, expectedTimeProp }) => {
      beforeEach(() => {
        createComponent({
          propsData: {
            timestampType,
          },
        });
      });

      it('displays correct text and passes correct `time` prop to `TimeAgoTooltip`', () => {
        expect(wrapper.findByText(expectedText).exists()).toBe(true);
        expect(findTimeAgoTooltip().props('time')).toBe(expectedTimeProp);
      });
    },
  );

  describe('when timestamp type is not available in project data', () => {
    beforeEach(() => {
      const { createdAt, ...projectWithoutCreatedAt } = project;
      createComponent({
        propsData: {
          project: projectWithoutCreatedAt,
        },
      });
    });

    it('does not render timestamp', () => {
      expect(findTimeAgoTooltip().exists()).toBe(false);
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
      expect(mergeRequestsLink.findComponent(GlIcon).props('name')).toBe('merge-request');
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

    const projectWithActions = {
      ...project,
      availableActions: [ACTION_EDIT, ACTION_DELETE],
      isForked: true,
      editPath,
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          project: projectWithActions,
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
        describe('when API call is successful', () => {
          it('calls deleteProject, properly sets loading state, and emits delete-complete event', async () => {
            deleteProject.mockResolvedValueOnce();

            await deleteModalFirePrimaryEvent();
            expect(deleteParams).toHaveBeenCalledWith(projectWithActions);
            expect(deleteProject).toHaveBeenCalledWith(projectWithActions.id, MOCK_DELETE_PARAMS);
            expect(findDeleteModal().props('confirmLoading')).toBe(true);

            await waitForPromises();

            expect(findDeleteModal().props('confirmLoading')).toBe(false);
            expect(wrapper.emitted('delete-complete')).toEqual([[]]);
            expect(renderDeleteSuccessToast).toHaveBeenCalledWith(projectWithActions, 'Project');
            expect(createAlert).not.toHaveBeenCalled();
          });
        });

        describe('when API call is not successful', () => {
          const error = new Error();

          it('calls deleteProject, properly sets loading state, and shows error alert', async () => {
            deleteProject.mockRejectedValue(error);
            await deleteModalFirePrimaryEvent();

            expect(deleteParams).toHaveBeenCalledWith(projectWithActions);
            expect(deleteProject).toHaveBeenCalledWith(projectWithActions.id, MOCK_DELETE_PARAMS);
            expect(findDeleteModal().props('confirmLoading')).toBe(true);

            await waitForPromises();

            expect(findDeleteModal().props('confirmLoading')).toBe(false);

            expect(wrapper.emitted('delete-complete')).toBeUndefined();
            expect(createAlert).toHaveBeenCalledWith({
              message:
                'An error occurred deleting the project. Please refresh the page to try again.',
              error,
              captureError: true,
            });
            expect(renderDeleteSuccessToast).not.toHaveBeenCalled();
          });
        });
      });
    });
  });
});
