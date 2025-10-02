import { GlAvatar, GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { groups } from '../groups_list/mock_data';

describe('ListItem', () => {
  let wrapper;

  const [group] = groups;

  const {
    data: {
      projects: { nodes: graphqlProjects },
    },
  } = membershipProjectsGraphQlResponse;

  const [project] = formatGraphQLProjects(graphqlProjects);

  const actions = {
    [ACTION_EDIT]: {
      href: '/foo',
    },
    [ACTION_DELETE]: {
      action: jest.fn(),
    },
  };

  const defaultPropsData = {
    resource: group,
  };

  const createComponent = ({
    mountFn = shallowMountExtended,
    propsData = {},
    stubs = {},
    scopedSlots = {},
  } = {}) => {
    wrapper = mountFn(ListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      scopedSlots: {
        'avatar-meta': '<div data-testid="avatar-meta"></div>',
        stats: '<div data-testid="stats"></div>',
        footer: '<div data-testid="footer"></div>',
        'children-toggle': '<div data-testid="children-toggle"></div>',
        children: '<div data-testid="children"></div>',
        ...scopedSlots,
      },
      stubs,
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findDescription = () => wrapper.findByTestId('description');
  const findListActions = () => wrapper.findComponent(ListActions);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  it('renders avatar', () => {
    createComponent({
      propsData: {
        avatarAttrs: { itemprop: 'image', labelLinkAttrs: { itemprop: 'name' } },
      },
      mountFn: mountExtended,
    });

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: group.avatarLabel,
      labelLink: group.relativeWebUrl,
      labelLinkAttrs: { itemprop: 'name' },
      entityId: group.id,
      entityName: group.fullName,
      src: group.avatarUrl,
      shape: 'rect',
    });

    expect(avatarLabeled.findComponent(GlAvatar).attributes()).toMatchObject({
      itemprop: 'image',
    });
  });

  describe('when resource.avatarLabelLink is defined', () => {
    const avatarLabelLink = '/foo';

    beforeEach(() => {
      createComponent({ propsData: { resource: { ...group, avatarLabelLink } } });
    });

    it('uses that for labeLink prop', () => {
      expect(findAvatarLabeled().props('labelLink')).toBe(avatarLabelLink);
    });
  });

  describe('when avatar label is clicked', () => {
    beforeEach(() => {
      createComponent();
      findAvatarLabeled().vm.$emit('label-link-click');
    });

    it('emits click-avatar event', () => {
      expect(wrapper.emitted('click-avatar')).toEqual([[]]);
    });
  });

  it('renders avatar meta slot', () => {
    createComponent({ stubs: { GlAvatarLabeled } });

    expect(wrapper.findByTestId('avatar-meta').exists()).toBe(true);
  });

  it('renders stats slot', () => {
    createComponent();

    expect(wrapper.findByTestId('stats').exists()).toBe(true);
  });

  it('renders footer slot', () => {
    createComponent();

    expect(wrapper.findByTestId('footer').exists()).toBe(true);
  });

  it('renders children-toggle slot', () => {
    createComponent();

    expect(wrapper.findByTestId('children-toggle').exists()).toBe(true);
  });

  it('renders children slot', () => {
    createComponent();

    expect(wrapper.findByTestId('children').exists()).toBe(true);
  });

  describe('when avatar-default slot is provided', () => {
    beforeEach(() => {
      createComponent({
        scopedSlots: { 'avatar-default': '<div data-testid="avatar-default"></div>' },
      });
    });

    it('renders slot instead of description', () => {
      expect(wrapper.findByTestId('avatar-default').exists()).toBe(true);
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when avatar-default slot is not provided', () => {
    it('renders description', () => {
      createComponent({ mountFn: mountExtended });

      expect(findDescription().exists()).toBe(true);
    });

    describe('when descriptionAttrs prop is provided', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          propsData: { descriptionAttrs: { itemprop: 'description' } },
        });
      });

      it('adds attributes to description', () => {
        expect(findDescription().attributes()).toMatchObject({ itemprop: 'description' });
      });
    });
  });

  describe('when `showIcon` prop is `true`', () => {
    it('shows icon based on `iconName` prop', () => {
      const iconName = 'group';

      createComponent({ propsData: { showIcon: true, iconName } });

      expect(wrapper.findComponent(GlIcon).props('name')).toBe(iconName);
    });
  });

  describe('when `showIcon` prop is `false`', () => {
    it('does not show icon', () => {
      createComponent();

      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });
  });

  describe('when actions prop is passed', () => {
    describe('when resource has available actions', () => {
      it('displays actions dropdown', () => {
        createComponent({
          propsData: {
            actions,
          },
        });

        expect(findListActions().props()).toMatchObject({
          actions,
          availableActions: group.availableActions,
        });
      });
    });

    describe('when resource does not have available actions', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            actions,
            resource: {
              ...group,
              availableActions: [],
            },
          },
        });
      });

      it('does not display actions dropdown', () => {
        expect(findListActions().exists()).toBe(false);
      });
    });
  });

  describe('when actions prop has not been passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });
  });

  describe('when actions slot is provided', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          actions,
        },
        scopedSlots: {
          actions: '<div data-testid="actions"></div>',
        },
      });
    });

    it('renders slot instead of list actions component', () => {
      expect(wrapper.findByTestId('actions').exists()).toBe(true);
      expect(findListActions().exists()).toBe(false);
    });
  });

  describe.each`
    resource   | timestampType                      | expectedText | expectedTimeProp
    ${group}   | ${TIMESTAMP_TYPE_CREATED_AT}       | ${'Created'} | ${'createdAt'}
    ${group}   | ${TIMESTAMP_TYPE_UPDATED_AT}       | ${'Updated'} | ${'updatedAt'}
    ${project} | ${TIMESTAMP_TYPE_LAST_ACTIVITY_AT} | ${'Updated'} | ${'lastActivityAt'}
    ${group}   | ${undefined}                       | ${'Created'} | ${'createdAt'}
  `(
    'when `timestampType` prop is $timestampType',
    ({ resource, timestampType, expectedText, expectedTimeProp }) => {
      beforeEach(() => {
        createComponent({
          propsData: {
            resource,
            timestampType,
          },
        });
      });

      it('displays correct text and passes correct `time` prop to `TimeAgoTooltip`', () => {
        expect(wrapper.findByText(expectedText).exists()).toBe(true);
        expect(findTimeAgoTooltip().props('time')).toBe(resource[expectedTimeProp]);
      });
    },
  );

  describe('when timestamp type is not available in resource data', () => {
    beforeEach(() => {
      const { createdAt, ...groupWithoutCreatedAt } = group;
      createComponent({
        propsData: {
          resource: groupWithoutCreatedAt,
        },
      });
    });

    it('does not render timestamp', () => {
      expect(findTimeAgoTooltip().exists()).toBe(false);
    });
  });

  describe('when contentTestid props is passed', () => {
    beforeEach(() => {
      createComponent({ propsData: { contentTestid: 'foo' } });
    });

    it('adds data-testid attribute to content', () => {
      expect(wrapper.findByTestId('foo').exists()).toBe(true);
    });
  });

  it('renders listItemClass prop on first div in li element', () => {
    createComponent({ propsData: { listItemClass: 'foo' } });

    expect(wrapper.element.firstChild.classList).toContain('foo');
  });
});
