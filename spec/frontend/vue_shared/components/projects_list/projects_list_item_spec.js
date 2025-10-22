import { nextTick } from 'vue';
import { GlAvatar, GlAvatarLabeled, GlIcon, GlTooltip } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import ListItemInactiveBadge from '~/vue_shared/components/resource_lists/list_item_inactive_badge.vue';
import CiCatalogBadge from '~/vue_shared/components/projects_list/ci_catalog_badge.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import { ACTION_DELETE, ACTION_EDIT } from '~/vue_shared/components/list_actions/constants';
import {
  PROJECT_VISIBILITY_TYPE,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_TYPE_ICON,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_DISABLED, FEATURABLE_ENABLED } from '~/featurable/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import { projects } from './mock_data';

jest.mock('~/alert');
jest.mock('~/api/projects_api');

describe('ProjectsListItem', () => {
  let wrapper;

  const [project] = projects;

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
  const findStorageSizeBadge = () => wrapper.findByTestId('storage-size');
  const findCiCatalogBadge = () => wrapper.findComponent(CiCatalogBadge);
  const findProjectDescription = () => wrapper.findByTestId('description-html');
  const findInactiveBadge = () => wrapper.findComponent(ListItemInactiveBadge);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findTopicBadges = () => wrapper.findComponent(TopicBadges);

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

  describe('when includeMicrodata prop is true', () => {
    beforeEach(() => {
      createComponent({ propsData: { includeMicrodata: true } });
    });

    it('adds microdata attributes to list element', () => {
      expect(wrapper.attributes()).toMatchObject({
        itemtype: 'https://schema.org/SoftwareSourceCode',
        itemprop: 'owns',
        itemscope: expect.any(String),
      });
    });

    it('adds microdata attributes to avatar', () => {
      const avatarLabeled = findAvatarLabeled();

      expect(avatarLabeled.props()).toMatchObject({
        labelLinkAttrs: { itemprop: 'name' },
      });

      expect(avatarLabeled.findComponent(GlAvatar).attributes()).toMatchObject({
        itemprop: 'image',
      });
    });

    it('adds microdata to description', () => {
      expect(findProjectDescription().attributes()).toMatchObject({ itemprop: 'description' });
    });
  });

  it('renders project avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: project.nameWithNamespace,
      labelLink: project.relativeWebUrl,
      entityId: project.id,
      entityName: project.nameWithNamespace,
      src: project.avatarUrl,
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

  describe('when project does not have statistics key', () => {
    beforeEach(createComponent);

    it('does not render storage size badge', () => {
      expect(findStorageSizeBadge().exists()).toBe(false);
    });
  });

  describe('when project has statistics key', () => {
    it('renders storage size in human size', () => {
      createComponent({
        propsData: { project: { ...project, statistics: { storageSize: 3072 } } },
      });

      expect(findStorageSizeBadge().text()).toBe('3.0 KiB');
    });

    describe('when storage size is null', () => {
      beforeEach(() => {
        createComponent({
          propsData: { project: { ...project, statistics: { storageSize: null } } },
        });
      });

      it('renders 0 B', () => {
        expect(findStorageSizeBadge().text()).toBe('0 B');
      });
    });

    describe('when statistics is null', () => {
      it('renders Unknown', () => {
        createComponent({
          propsData: { project: { ...project, statistics: null } },
        });

        expect(findStorageSizeBadge().text()).toBe('Unknown');
      });
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

  describe('when there is no stars count stat data', () => {
    it('does not render stars count', () => {
      createComponent({
        propsData: { project: { ...project, starCount: undefined } },
      });

      expect(findStarsStat().exists()).toBe(false);
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
    beforeEach(() => {
      createComponent({
        propsData: {
          project: { ...project, topics: ['javascript'] },
        },
      });
    });

    it('renders topic badges component', () => {
      expect(findTopicBadges().exists()).toBe(true);
    });

    describe('when topic badges component emits click event', () => {
      beforeEach(() => {
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

    describe('when project is not published in the CI Catalog', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            project: {
              ...project,
              isCatalogResource: true,
              isPublished: false,
            },
          },
        });
      });

      it('renders badge without a link', () => {
        expect(findCiCatalogBadge().props()).toEqual({
          isPublished: false,
          exploreCatalogPath: null,
        });
      });
    });
  });

  describe('when project is published in the CI Catalog', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          project: {
            ...project,
            isCatalogResource: true,
            isPublished: true,
            exploreCatalogPath: `/catalog/${project.pathWithNamespace}`,
          },
        },
      });
    });

    it('renders badge with correct link', () => {
      expect(findCiCatalogBadge().props()).toEqual({
        isPublished: true,
        exploreCatalogPath: `/catalog/${project.pathWithNamespace}`,
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
});
