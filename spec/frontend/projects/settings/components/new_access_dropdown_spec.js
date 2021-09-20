import {
  GlSprintf,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { getUsers, getGroups, getDeployKeys } from '~/projects/settings/api/access_dropdown_api';
import AccessDropdown, { i18n } from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from '~/projects/settings/constants';

jest.mock('~/projects/settings/api/access_dropdown_api', () => ({
  getUsers: jest.fn().mockResolvedValue({ data: [{ id: 1 }, { id: 2 }] }),
  getGroups: jest.fn().mockResolvedValue({ data: [{ id: 3 }, { id: 4 }, { id: 5 }] }),
  getDeployKeys: jest.fn().mockResolvedValue({
    data: [
      { id: 6, title: 'key1', fingerprint: 'abcdefghijklmnop', owner: { name: 'user1' } },
      { id: 7, title: 'key1', fingerprint: 'abcdefghijklmnop', owner: { name: 'user2' } },
      { id: 8, title: 'key1', fingerprint: 'abcdefghijklmnop', owner: { name: 'user3' } },
      { id: 9, title: 'key1', fingerprint: 'abcdefghijklmnop', owner: { name: 'user4' } },
    ],
  }),
}));

describe('Access Level Dropdown', () => {
  let wrapper;
  const mockAccessLevelsData = [
    {
      id: 42,
      text: 'Dummy Role',
    },
  ];

  const createComponent = ({
    accessLevelsData = mockAccessLevelsData,
    accessLevel = ACCESS_LEVELS.PUSH,
    hasLicense = true,
  } = {}) => {
    wrapper = shallowMount(AccessDropdown, {
      propsData: {
        accessLevelsData,
        accessLevel,
        hasLicense,
      },
      stubs: {
        GlSprintf,
        GlDropdown,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggleLabel = () => findDropdown().props('text');
  const findAllDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findAllDropdownHeaders = () => findDropdown().findAllComponents(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  describe('data request', () => {
    it('should make an api call for users, groups && deployKeys when user has a license', () => {
      createComponent();
      expect(getUsers).toHaveBeenCalled();
      expect(getGroups).toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalled();
    });

    it('should make an api call for deployKeys but not for users or groups when user does not have a license', () => {
      createComponent({ hasLicense: false });
      expect(getUsers).not.toHaveBeenCalled();
      expect(getGroups).not.toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalled();
    });

    it('should make api calls when search query is updated', async () => {
      createComponent();
      const query = 'root';

      findSearchBox().vm.$emit('input', query);
      await nextTick();
      expect(getUsers).toHaveBeenCalledWith(query);
      expect(getGroups).toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalledWith(query);
    });
  });
  describe('layout', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders headers for each section ', () => {
      expect(findAllDropdownHeaders()).toHaveLength(4);
    });

    it('renders dropdown item for each access level type', () => {
      expect(findAllDropdownItems()).toHaveLength(10);
    });
  });
  describe('toggleLabel', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    const triggerNthItemClick = async (n) => {
      findAllDropdownItems().at(n).trigger('click');
      await nextTick();
    };

    it('when no items selected displays a default label and has default CSS class ', () => {
      expect(findDropdownToggleLabel()).toBe(i18n.selectUsers);
      expect(findDropdown().props('toggleClass')).toBe('gl-text-gray-500!');
    });

    it('displays a number of selected items for each group level', async () => {
      findAllDropdownItems().wrappers.forEach((item) => {
        item.trigger('click');
      });
      await nextTick();
      expect(findDropdownToggleLabel()).toBe('1 role, 2 users, 4 deploy keys, 3 groups');
    });

    it('with only role selected displays the role name and has no class applied', async () => {
      await triggerNthItemClick(0);
      expect(findDropdownToggleLabel()).toBe('Dummy Role');
      expect(findDropdown().props('toggleClass')).toBe('');
    });

    it('with only groups selected displays the number of selected groups', async () => {
      await triggerNthItemClick(1);
      await triggerNthItemClick(2);
      await triggerNthItemClick(3);
      expect(findDropdownToggleLabel()).toBe('3 groups');
      expect(findDropdown().props('toggleClass')).toBe('');
    });

    it('with only users selected displays the number of selected users', async () => {
      await triggerNthItemClick(4);
      await triggerNthItemClick(5);
      expect(findDropdownToggleLabel()).toBe('2 users');
      expect(findDropdown().props('toggleClass')).toBe('');
    });

    it('with users and groups selected displays the number of selected users & groups', async () => {
      await triggerNthItemClick(1);
      await triggerNthItemClick(2);
      await triggerNthItemClick(4);
      await triggerNthItemClick(5);
      expect(findDropdownToggleLabel()).toBe('2 users, 2 groups');
      expect(findDropdown().props('toggleClass')).toBe('');
    });

    it('with users and deploy keys selected displays the number of selected users & keys', async () => {
      await triggerNthItemClick(1);
      await triggerNthItemClick(2);
      await triggerNthItemClick(6);
      expect(findDropdownToggleLabel()).toBe('1 deploy key, 2 groups');
      expect(findDropdown().props('toggleClass')).toBe('');
    });
  });

  describe('selecting an item', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('selects the item on click and deselects on the next click ', async () => {
      const item = findAllDropdownItems().at(1);
      item.trigger('click');
      await nextTick();
      expect(item.props('isChecked')).toBe(true);
      item.trigger('click');
      await nextTick();
      expect(item.props('isChecked')).toBe(false);
    });

    it('emits an update on selection ', async () => {
      const spy = jest.spyOn(wrapper.vm, '$emit');
      findAllDropdownItems().at(4).trigger('click');
      findAllDropdownItems().at(3).trigger('click');
      await nextTick();
      expect(spy).toHaveBeenLastCalledWith('select', [
        { id: 5, type: 'group' },
        { id: 1, type: 'user' },
      ]);
    });
  });

  describe('on dropdown open', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should set the search input focus', () => {
      wrapper.vm.$refs.search.focusInput = jest.fn();
      findDropdown().vm.$emit('shown');

      expect(wrapper.vm.$refs.search.focusInput).toHaveBeenCalled();
    });
  });
});
