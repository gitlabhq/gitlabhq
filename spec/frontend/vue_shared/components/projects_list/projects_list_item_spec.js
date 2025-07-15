import { nextTick } from 'vue';
import { GlAvatarLabeled, GlIcon, GlTooltip } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectListItemDescription from '~/vue_shared/components/projects_list/project_list_item_description.vue';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import ProjectListItemInactiveBadge from '~/vue_shared/components/projects_list/project_list_item_inactive_badge.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import ProjectListItemDelayedDeletionModalFooter from '~/vue_shared/components/projects_list/project_list_item_delayed_deletion_modal_footer.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import waitForPromises from 'helpers/wait_for_promises';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  PROJECT_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_DISABLED, FEATURABLE_ENABLED } from '~/featurable/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import {
  renderDeleteSuccessToast,
  deleteParams,
} from '~/vue_shared/components/projects_list/utils';
import { deleteProject } from '~/api/projects_api';
import { createAlert } from '~/alert';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

jest.mock('~/vue_shared/components/projects_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/projects_list/utils'),
  renderDeleteSuccessToast: jest.fn(),
  deleteParams: jest.fn(() => MOCK_DELETE_PARAMS),
}));
jest.mock('~/alert');
jest.mock('~/api/projects_api');

describe('ProjectsListItem', () => {
  let wrapper;

  const [{ permissions, ...mockProject }] = convertObjectPropsToCamelCase(projects, { deep: true });

  const project = {
    ...mockProject,
    accessLevel: {
      integerValue: permissions.projectAccess.accessLevel,
    },
    avatarUrl: 'avatar.jpg',
    avatarLabel: mockProject.nameWithNamespace,
    isForked: false,
    relativeWebUrl: `/${mockProject.fullPath}`,
  };

  const defaultPropsData = {
    project,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(ProjectsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      stubs: { GlTooltip: stubComponent(GlTooltip) },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findStarsStat = () => wrapper.findByTestId('stars-btn');
  const findMergeRequestsStat = () => wrapper.findByTestId('mrs-btn');
  const findIssuesStat = () => wrapper.findByTestId('issues-btn');
  const findForksStat = () => wrapper.findByTestId('forks-btn');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);
  const findListActions = () => wrapper.findComponent(ProjectListItemActions);
  const findAccessLevelBadge = () => wrapper.findByTestId('user-access-role');
  const findCiCatalogBadge = () => wrapper.findByTestId('ci-catalog-badge');
  const findProjectDescription = () => wrapper.findComponent(ProjectListItemDescription);
  const findInactiveBadge = () => wrapper.findComponent(ProjectListItemInactiveBadge);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findTopicBadges = () => wrapper.findComponent(TopicBadges);
  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findDelayedDeletionModalFooter = () =>
    wrapper.findComponent(ProjectListItemDelayedDeletionModalFooter);
  const deleteModalFirePrimaryEvent = async () => {
    findDeleteModal().vm.$emit('primary');
    await nextTick();
  };
  const findTooltipByTarget = (target) =>
    wrapper
      .findAllComponents(GlTooltip)
      .wrappers.find((tooltip) => tooltip.props('target')() === target.element);

  describe('when ListItem component emits click-avatar event', () => {
    beforeEach(() => {
      createComponent();
      wrapper.findComponent(ListItem).vm.$emit('click-avatar');
    });

    it('emits click-avatar event', () => {
      expect(wrapper.emitted('click-avatar')).toEqual([[]]);
    });
  });

  it('renders project avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: project.nameWithNamespace,
      labelLink: project.relativeWebUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': project.id.toString(),
      'entity-name': project.nameWithNamespace,
      src: defaultPropsData.project.avatarUrl,
      shape: 'rect',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = findTooltipByTarget(icon);

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]);
    expect(tooltip.text()).toBe(PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]);
  });

  it('emits hover-visibility event when visibility icon tooltip is shown', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    findTooltipByTarget(icon).vm.$emit('shown');

    expect(wrapper.emitted('hover-visibility')).toEqual([[project.visibility]]);
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
        propsData: { project: { ...project, accessLevel: null } },
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

    expect(findStarsStat().props()).toEqual({
      href: `${project.relativeWebUrl}/-/starrers`,
      tooltipText: 'Stars',
      a11yText: `${project.avatarLabel} has ${project.starCount} stars`,
      iconName: 'star-o',
      stat: project.starCount.toString(),
    });
  });

  describe('when stars count stat emits hover and click events', () => {
    beforeEach(async () => {
      createComponent();
      findStarsStat().vm.$emit('hover');
      findStarsStat().vm.$emit('click');

      await nextTick();
    });

    it('emits hover-stat and click-stat events', () => {
      expect(wrapper.emitted()).toEqual({
        'click-stat': [['stars-count']],
        'hover-stat': [['stars-count']],
      });
    });
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
    beforeEach(() => {
      createComponent({
        propsData: {
          project: {
            ...project,
            openMergeRequestsCount: 5,
          },
        },
      });
    });

    it('renders merge requests count', () => {
      expect(findMergeRequestsStat().props()).toEqual({
        href: `${project.relativeWebUrl}/-/merge_requests`,
        tooltipText: 'Merge requests',
        a11yText: `${project.avatarLabel} has 5 open merge requests`,
        iconName: 'merge-request',
        stat: '5',
      });
    });

    describe('when merge request stat emits hover and click events', () => {
      beforeEach(() => {
        findMergeRequestsStat().vm.$emit('hover');
        findMergeRequestsStat().vm.$emit('click');
      });

      it('emits hover-stat and click-stat events', () => {
        expect(wrapper.emitted()).toEqual({
          'click-stat': [['mrs-count']],
          'hover-stat': [['mrs-count']],
        });
      });
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

      expect(findMergeRequestsStat().exists()).toBe(false);
    });
  });

  describe('when issues are enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders issues count', () => {
      expect(findIssuesStat().props()).toEqual({
        href: `${project.relativeWebUrl}/-/issues`,
        tooltipText: 'Issues',
        a11yText: `${project.avatarLabel} has ${project.openIssuesCount} open issues`,
        iconName: 'issues',
        stat: project.openIssuesCount.toString(),
      });
    });

    describe('when issues stat emits hover and click events', () => {
      beforeEach(() => {
        findIssuesStat().vm.$emit('hover');
        findIssuesStat().vm.$emit('click');
      });

      it('emits hover-stat and click-stat events', () => {
        expect(wrapper.emitted()).toEqual({
          'click-stat': [['issues-count']],
          'hover-stat': [['issues-count']],
        });
      });
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

      expect(findIssuesStat().exists()).toBe(false);
    });
  });

  describe('when forking is enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders forks count', () => {
      expect(findForksStat().props()).toEqual({
        href: `${project.relativeWebUrl}/-/forks`,
        a11yText: `${project.avatarLabel} has ${project.forksCount} forks`,
        tooltipText: 'Forks',
        iconName: 'fork',
        stat: project.forksCount.toString(),
      });
    });

    describe('when forking stat emits hover and click events', () => {
      beforeEach(() => {
        findForksStat().vm.$emit('hover');
        findForksStat().vm.$emit('click');
      });

      it('emits hover-stat and click-stat events', () => {
        expect(wrapper.emitted()).toEqual({
          'click-stat': [['forks-count']],
          'hover-stat': [['forks-count']],
        });
      });
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

      expect(findForksStat().exists()).toBe(false);
    });
  });

  describe('project with topics', () => {
    it('renders topic badges component', () => {
      createComponent();

      expect(findTopicBadges().exists()).toBe(true);
    });

    describe('when topic badges component emits click event', () => {
      beforeEach(() => {
        createComponent();
        findTopicBadges().vm.$emit('click');
      });

      it('emits click-topic event', () => {
        expect(wrapper.emitted('click-topic')).toEqual([[]]);
      });
    });
  });

  describe('project without topics', () => {
    it('does not render topic badges component', () => {
      createComponent({
        propsData: {
          project: {
            ...project,
            topics: [],
          },
        },
      });

      expect(findTopicBadges().exists()).toBe(false);
    });
  });

  it('renders project description', () => {
    createComponent();

    expect(findProjectDescription().exists()).toBe(true);
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
      expect(findListActions().exists()).toBe(true);
    });

    describe('when delete action is fired', () => {
      beforeEach(() => {
        findListActions().vm.$emit('delete');
      });

      it('displays confirmation modal with correct props', () => {
        expect(wrapper.findComponent(DeleteModal).props()).toMatchObject({
          visible: true,
          confirmPhrase: project.fullPath,
          nameWithNamespace: project.nameWithNamespace,
          isFork: true,
          issuesCount: '0',
          forksCount: '0',
          starsCount: '0',
          confirmLoading: false,
        });
      });

      describe('when deletion is confirmed', () => {
        describe('when API call is successful', () => {
          it('calls deleteProject, properly sets loading state, and emits refetch event', async () => {
            deleteProject.mockResolvedValueOnce();

            await deleteModalFirePrimaryEvent();
            expect(deleteParams).toHaveBeenCalledWith(projectWithActions);
            expect(deleteProject).toHaveBeenCalledWith(projectWithActions.id, MOCK_DELETE_PARAMS);
            expect(findDeleteModal().props('confirmLoading')).toBe(true);

            await waitForPromises();

            expect(findDeleteModal().props('confirmLoading')).toBe(false);
            expect(wrapper.emitted('refetch')).toEqual([[]]);
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

            expect(wrapper.emitted('refetch')).toBeUndefined();
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

  describe('CI Catalog Badge', () => {
    describe('when project is not in the CI Catalog', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render badge', () => {
        expect(findCiCatalogBadge().exists()).toBe(false);
      });
    });

    describe('when project is in the CI Catalog', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            project: {
              ...project,
              isCatalogResource: true,
              exploreCatalogPath: `/catalog/${project.pathWithNamespace}`,
            },
          },
        });
      });

      it('renders badge with correct link', () => {
        expect(findCiCatalogBadge().exists()).toBe(true);
        expect(findCiCatalogBadge().text()).toBe('CI/CD Catalog project');
        expect(findCiCatalogBadge().props('href')).toBe(`/catalog/${project.pathWithNamespace}`);
      });
    });
  });

  describe('when project does not have a pipeline status', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render CI icon component', () => {
      expect(wrapper.findComponent(CiIcon).exists()).toBe(false);
    });
  });

  describe('when project has pipeline status', () => {
    const detailedStatus = {
      detailsPath: '/foo/bar',
      icon: 'status_warning',
      id: '1',
      text: 'Warning',
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          project: {
            ...project,
            pipeline: {
              detailedStatus,
            },
          },
        },
      });
    });

    it('renders CI icon component', () => {
      expect(wrapper.findComponent(CiIcon).props('status')).toBe(detailedStatus);
    });
  });

  it('adds data-testid attribute to content', () => {
    createComponent();

    expect(wrapper.findByTestId('project-content').exists()).toBe(true);
  });

  it('renders listItemClass prop on first div in li element', () => {
    createComponent({ propsData: { listItemClass: 'foo' } });

    expect(wrapper.element.firstChild.classList).toContain('foo');
  });

  describe('ProjectListItemDelayedDeletionModalFooter', () => {
    const deleteProps = {
      project: {
        ...project,
        availableActions: [ACTION_DELETE],
        actionLoadingStates: { [ACTION_DELETE]: false },
      },
    };

    it('renders modal footer', () => {
      createComponent({ propsData: deleteProps });
      findListActions().vm.$emit('delete');

      expect(findDeleteModal().exists()).toBe(true);
      expect(findDelayedDeletionModalFooter().exists()).toBe(false);
    });
  });
});
