import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ItemsSelector from '~/projects/settings/branch_rules/components/items_selector.vue';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import { USERS_TYPE, GROUPS_TYPE } from '~/vue_shared/components/list_selector/constants';
import {
  usersMock,
  groupsMock,
} from 'ee_else_ce_jest/projects/settings/branch_rules/components/mock_data';

describe('Items selector component', () => {
  let wrapper;

  const findListSelector = () => wrapper.findComponent(ListSelector);

  const createComponent = (propsData = {}) => {
    const itemsByType = propsData.type === USERS_TYPE ? usersMock : groupsMock;
    wrapper = shallowMountExtended(ItemsSelector, {
      propsData: {
        items: itemsByType,
        ...propsData,
      },
      provide: {
        projectId: 7,
      },
    });
  };

  it('renders the list selector component', () => {
    createComponent({ type: USERS_TYPE });
    expect(findListSelector().exists()).toBe(true);
  });

  it('passes the correct props to the list selector component of type user', () => {
    createComponent({
      usersOptions: { active: true },
      type: USERS_TYPE,
    });

    expect(findListSelector().props('type')).toBe(USERS_TYPE);
    expect(findListSelector().props('selectedItems')).toEqual(usersMock);
    expect(findListSelector().props('usersQueryOptions')).toEqual({ active: true });
  });

  it('passes the correct props to the list selector component of type group', () => {
    createComponent({
      type: GROUPS_TYPE,
    });

    expect(findListSelector().props('type')).toBe(GROUPS_TYPE);
    expect(findListSelector().props('selectedItems')).toEqual(groupsMock);
    expect(findListSelector().props('disableNamespaceDropdown')).toBe(true);
    expect(findListSelector().props('isGroupsWithProjectAccess')).toBe(true);
    expect(findListSelector().props('projectId')).toBe(7);
  });

  it('emits the change event with the updated selectedItems when an item is selected', async () => {
    createComponent({ type: USERS_TYPE });
    const listSelectorComponent = wrapper.findComponent(ListSelector);
    const newItem = { id: 3, name: 'Item 3' };

    await listSelectorComponent.vm.$emit('select', newItem);

    expect(wrapper.emitted('change')).toEqual([[usersMock.concat(newItem)]]);
  });

  it('emits the change event with the updated selectedItems when an item is deleted', async () => {
    createComponent({ type: USERS_TYPE });
    const listSelectorComponent = wrapper.findComponent(ListSelector);
    await listSelectorComponent.vm.$emit('delete', '123');
    expect(wrapper.emitted('change')).toEqual([[usersMock.slice(1)]]);
  });
});
