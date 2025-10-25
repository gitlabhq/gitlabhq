import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

describe('ListActions', () => {
  let wrapper;

  const defaultPropsData = {
    actions: {
      [ACTION_EDIT]: {
        href: '/-/edit',
      },
      [ACTION_DELETE]: {
        action: () => {},
      },
    },
    availableActions: [ACTION_EDIT, ACTION_DELETE],
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ListActions, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const getDropdownItems = () =>
    findDropdown()
      .findAllComponents(GlDisclosureDropdownItem)
      .wrappers.map((dropdownItem) => dropdownItem.props('item'));

  it('allows extending of base actions', () => {
    createComponent();

    expect(getDropdownItems()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
      },
      {
        text: 'Delete',
        variant: 'danger',
        action: expect.any(Function),
      },
    ]);
  });

  it('allows adding custom actions', () => {
    const ACTION_CUSTOM = 'custom';

    createComponent({
      propsData: {
        actions: {
          ...defaultPropsData.actions,
          [ACTION_CUSTOM]: {
            text: 'Custom',
            action: () => {},
          },
        },
        availableActions: [ACTION_EDIT, ACTION_CUSTOM, ACTION_DELETE],
      },
    });

    expect(getDropdownItems()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
      },
      {
        text: 'Custom',
        action: expect.any(Function),
      },
      {
        text: 'Delete',
        variant: 'danger',
        action: expect.any(Function),
      },
    ]);
  });

  it('only shows available actions', () => {
    createComponent({
      propsData: {
        availableActions: [ACTION_EDIT],
      },
    });

    expect(getDropdownItems()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
      },
    ]);
  });

  it('renders `GlDisclosureDropdown` with expected appearance related props', () => {
    createComponent();

    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      noCaret: true,
      toggleText: 'Actions',
      textSrOnly: true,
      placement: 'bottom-end',
      category: 'tertiary',
    });
  });
});
