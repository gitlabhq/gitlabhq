import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { last } from 'lodash';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { getSubGroups, getUsers } from '~/groups/settings/api/access_dropdown_api';
import AccessDropdown from '~/groups/settings/components/access_dropdown.vue';

jest.mock('~/groups/settings/api/access_dropdown_api', () => ({
  getSubGroups: jest.fn().mockResolvedValue({
    data: [
      { id: 4, name: 'group4' },
      { id: 5, name: 'group5' },
      { id: 6, name: 'group6' },
    ],
  }),
  getUsers: jest.fn().mockResolvedValue({
    data: [
      { id: 1, name: 'user1', avatar_url: 'avatar1' },
      { id: 2, name: 'user2', avatar_url: 'avatar2' },
      { id: 3, name: 'user3', avatar_url: 'avatar3' },
    ],
  }),
}));

const accessLevelsData = [
  {
    id: 7,
    text: 'role1',
  },
  {
    id: 8,
    text: 'role2',
  },
];

describe('Access Level Dropdown', () => {
  let wrapper;
  const createComponent = ({ ...optionalProps } = {}) => {
    wrapper = shallowMount(AccessDropdown, {
      propsData: {
        ...optionalProps,
      },
      stubs: {
        GlDropdown,
      },
    });
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggleLabel = () => findDropdown().props('text');
  const findAllDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findAllDropdownHeaders = () => findDropdown().findAllComponents(GlDropdownSectionHeader);

  const findDropdownItemWithText = (items, text) =>
    items.filter((item) => item.text().includes(text)).at(0);

  describe('data request', () => {
    it('should make an api call for sub-groups', () => {
      createComponent();
      expect(getSubGroups).toHaveBeenCalledWith({
        includeParentDescendants: true,
        includeParentSharedGroups: true,
        search: '',
      });
    });

    it('should make an api call for group members if `showUsers` prop is `true`', () => {
      createComponent({ showUsers: true });
      expect(getUsers).toHaveBeenCalledTimes(1);
    });

    it('should not make an api call for group members if `showUsers` prop is `false`', () => {
      createComponent();
      expect(getUsers).not.toHaveBeenCalled();
    });

    describe('when user does not have a license', () => {
      beforeEach(() => {
        createComponent({ hasLicense: false });
      });

      it('should not make an API call sub groups', () => {
        expect(getSubGroups).not.toHaveBeenCalled();
      });

      it('should not make an API call group members', () => {
        expect(getUsers).not.toHaveBeenCalled();
      });
    });

    it('should make api calls when search query is updated', async () => {
      createComponent({ showUsers: true });
      const search = 'root';

      findSearchBox().vm.$emit('input', search);
      await nextTick();
      expect(getSubGroups).toHaveBeenCalledWith({
        includeParentDescendants: true,
        includeParentSharedGroups: true,
        search,
      });
      expect(getUsers).toHaveBeenCalledWith(search);
    });
  });

  describe('layout', () => {
    beforeEach(async () => {
      createComponent({
        accessLevelsData,
        showUsers: true,
      });
      await waitForPromises();
    });

    it.each`
      header      | index
      ${'Roles'}  | ${0}
      ${'Groups'} | ${1}
      ${'Users'}  | ${2}
    `('renders header for $header at $index', ({ header, index }) => {
      expect(findAllDropdownHeaders().at(index).text()).toBe(header);
    });

    it('renders dropdown item for each access level type', () => {
      expect(findAllDropdownItems()).toHaveLength(8);
    });
  });

  describe('toggleLabel', () => {
    it('when no items selected and custom label provided, displays it', () => {
      const customLabel = 'Set the access level';
      createComponent({ label: customLabel });
      expect(findDropdownToggleLabel()).toBe(customLabel);
    });

    it('when no items selected, displays a default fallback label', () => {
      createComponent();
      expect(findDropdownToggleLabel()).toBe('Select groups');
    });

    it('displays selected items for each group level', async () => {
      createComponent({ accessLevelsData, showUsers: true });
      await waitForPromises();

      findAllDropdownItems().wrappers.forEach((item) => {
        item.trigger('click');
      });
      await nextTick();
      expect(findDropdownToggleLabel()).toBe('2 roles, 3 groups, 3 users');
    });

    it('with only role selected displays the role name', async () => {
      createComponent({ accessLevelsData, showUsers: true });
      await waitForPromises();

      await findDropdownItemWithText(findAllDropdownItems(), 'role1').trigger('click');
      expect(findDropdownToggleLabel()).toBe('role1');
    });

    it('with only groups selected displays the number of selected groups', async () => {
      createComponent();
      await waitForPromises();

      await findDropdownItemWithText(findAllDropdownItems(), 'group4').trigger('click');
      expect(findDropdownToggleLabel()).toBe('1 group');
    });

    it('with only users selected displays the number of selected users', async () => {
      createComponent({ showUsers: true });
      await waitForPromises();

      await findDropdownItemWithText(findAllDropdownItems(), 'user1').trigger('click');
      await findDropdownItemWithText(findAllDropdownItems(), 'user2').trigger('click');
      expect(findDropdownToggleLabel()).toBe('2 users');
    });

    it('with users and groups selected displays the number of selected users & groups', async () => {
      createComponent({ showUsers: true });
      await waitForPromises();

      await findDropdownItemWithText(findAllDropdownItems(), 'group4').trigger('click');
      await findDropdownItemWithText(findAllDropdownItems(), 'user2').trigger('click');
      expect(findDropdownToggleLabel()).toBe('1 group, 1 user');
    });
  });

  describe('selecting an item', () => {
    it('selects the item on click and deselects on the next click', async () => {
      createComponent();
      await waitForPromises();

      const item = findAllDropdownItems().at(1);
      item.trigger('click');
      await nextTick();
      expect(item.props('isChecked')).toBe(true);
      item.trigger('click');
      await nextTick();
      expect(item.props('isChecked')).toBe(false);
    });

    it('emits a formatted update on selection', async () => {
      createComponent({ accessLevelsData, showUsers: true });
      await waitForPromises();
      const dropdownItems = findAllDropdownItems();

      findDropdownItemWithText(dropdownItems, 'role1').trigger('click');
      findDropdownItemWithText(dropdownItems, 'group4').trigger('click');
      findDropdownItemWithText(dropdownItems, 'user3').trigger('click');

      expect(last(wrapper.emitted('select'))[0]).toStrictEqual([
        { access_level: 7 },
        { group_id: 4 },
        { user_id: 3 },
      ]);
    });
  });
});
