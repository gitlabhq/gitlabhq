import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
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

  const createComponent = ({ propsData = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(ListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      scopedSlots: {
        'avatar-meta': '<div data-testid="avatar-meta"></div>',
        stats: '<div data-testid="stats"></div>',
        footer: '<div data-testid="footer"></div>',
      },
      stubs,
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findGroupDescription = () => wrapper.findByTestId('description');
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

  describe('when resource has a description', () => {
    it('renders description', () => {
      const descriptionHtml = '<p>Foo bar</p>';

      createComponent({
        propsData: {
          resource: {
            ...resource,
            descriptionHtml,
          },
        },
      });

      expect(findGroupDescription().element.innerHTML).toBe(descriptionHtml);
    });
  });

  describe('when resource does not have a description', () => {
    it('does not render description', () => {
      createComponent({
        propsData: {
          resource: {
            ...resource,
            descriptionHtml: null,
          },
        },
      });

      expect(findGroupDescription().exists()).toBe(false);
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

  describe('when actions prop has not been passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });
  });

  describe('when resource does not have available actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });
  });

  describe.each`
    timestampType                | expectedText | expectedTimeProp
    ${TIMESTAMP_TYPE_CREATED_AT} | ${'Created'} | ${resource.createdAt}
    ${TIMESTAMP_TYPE_UPDATED_AT} | ${'Updated'} | ${resource.updatedAt}
    ${undefined}                 | ${'Created'} | ${resource.createdAt}
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
});
