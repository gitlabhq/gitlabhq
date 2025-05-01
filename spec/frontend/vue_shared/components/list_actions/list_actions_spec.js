import { GlDisclosureDropdown } from '@gitlab/ui';
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
  const getDropdownItemsProp = () => findDropdown().props('items');

  it('allows extending of base actions', () => {
    createComponent();

    expect(getDropdownItemsProp()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
        order: 1,
      },
      {
        text: 'Delete',
        variant: 'danger',
        action: expect.any(Function),
        order: 4,
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

    expect(getDropdownItemsProp()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
        order: 1,
      },
      {
        text: 'Custom',
        action: expect.any(Function),
      },
      {
        text: 'Delete',
        variant: 'danger',
        action: expect.any(Function),
        order: 4,
      },
    ]);
  });

  it('only shows available actions', () => {
    createComponent({
      propsData: {
        availableActions: [ACTION_EDIT],
      },
    });

    expect(getDropdownItemsProp()).toEqual([
      {
        text: 'Edit',
        href: '/-/edit',
        order: 1,
      },
    ]);
  });

  it('displays actions in the order set in `availableActions` prop', () => {
    createComponent({
      propsData: {
        availableActions: [ACTION_DELETE, ACTION_EDIT],
      },
    });

    expect(getDropdownItemsProp()).toEqual([
      {
        text: 'Delete',
        variant: 'danger',
        action: expect.any(Function),
        order: 4,
      },
      {
        text: 'Edit',
        href: '/-/edit',
        order: 1,
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
