import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { groups } from '../groups_list/mock_data';

describe('ListItem', () => {
  let wrapper;

  const [resource] = groups;
  const actions = {
    [ACTION_EDIT]: {
      href: '/foo',
    },
    [ACTION_DELETE]: {
      action: jest.fn(),
    },
  };

  const defaultPropsData = {
    resource,
  };

  const createComponent = ({ propsData = {}, stubs = {}, scopedSlots = {} } = {}) => {
    wrapper = shallowMountExtended(ListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      scopedSlots: {
        'avatar-meta': '<div data-testid="avatar-meta"></div>',
        stats: '<div data-testid="stats"></div>',
        footer: '<div data-testid="footer"></div>',
        ...scopedSlots,
      },
      stubs,
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findDescription = () => wrapper.findComponent(ListItemDescription);
  const findListActions = () => wrapper.findComponent(ListActions);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  it('renders avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: resource.avatarLabel,
      labelLink: resource.webUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': resource.id.toString(),
      'entity-name': resource.fullName,
      src: resource.avatarUrl,
      shape: 'rect',
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
    describe('when resource has a description', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders description', () => {
        expect(findDescription().props('descriptionHtml')).toBe(
          defaultPropsData.resource.descriptionHtml,
        );
      });
    });

    describe('when resource does not have a description', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            resource: {
              ...resource,
              descriptionHtml: null,
            },
          },
        });
      });

      it('does not render description', () => {
        expect(findDescription().exists()).toBe(false);
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
          availableActions: resource.availableActions,
        });
      });
    });

    describe('when resource does not have available actions', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            actions,
            resource: {
              ...resource,
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
    timestampType                      | expectedText | expectedTimeProp
    ${TIMESTAMP_TYPE_CREATED_AT}       | ${'Created'} | ${resource.createdAt}
    ${TIMESTAMP_TYPE_UPDATED_AT}       | ${'Updated'} | ${resource.updatedAt}
    ${TIMESTAMP_TYPE_LAST_ACTIVITY_AT} | ${'Updated'} | ${resource.lastActivityAt}
    ${undefined}                       | ${'Created'} | ${resource.createdAt}
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

  describe('when timestamp type is not available in resource data', () => {
    beforeEach(() => {
      const { createdAt, ...resourceWithoutCreatedAt } = resource;
      createComponent({
        propsData: {
          resource: resourceWithoutCreatedAt,
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
});
