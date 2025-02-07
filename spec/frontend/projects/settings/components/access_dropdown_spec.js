import {
  GlSprintf,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { last } from 'lodash';
import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { getUsers, getGroups, getDeployKeys } from '~/projects/settings/api/access_dropdown_api';
import AccessDropdown, { i18n } from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS, LEVEL_TYPES } from '~/projects/settings/constants';

jest.mock('~/projects/settings/api/access_dropdown_api', () => ({
  getGroups: jest.fn().mockResolvedValue({
    data: [
      { id: 4, name: 'group4' },
      { id: 5, name: 'group5' },
      { id: 6, name: 'group6' },
    ],
  }),
  getUsers: jest.fn().mockResolvedValue({
    data: [
      { id: 7, name: 'user7' },
      { id: 8, name: 'user8' },
      { id: 9, name: 'user9' },
    ],
  }),
  getDeployKeys: jest.fn().mockResolvedValue({
    data: [
      {
        id: 10,
        title: 'key10',
        fingerprint: 'md5-abcdefghijklmnop',
        fingerprint_sha256: 'sha256-abcdefghijklmnop',
        owner: { name: 'user1' },
      },
      {
        id: 11,
        title: 'key11',
        fingerprint_sha256: 'sha256-abcdefghijklmnop',
        owner: { name: 'user2' },
      },
      { id: 12, title: 'key12', fingerprint: 'md5-abcdefghijklmnop', owner: { name: 'user3' } },
    ],
  }),
}));

describe('Access Level Dropdown', () => {
  beforeEach(() => {
    window.gon = { abilities: { adminProject: true } };
  });

  let wrapper;
  const defaultToggleClass = '!gl-text-subtle';
  const mockAccessLevelsData = [
    {
      id: 1,
      text: 'role1',
    },
    {
      id: 2,
      text: 'role2',
    },
    {
      id: 3,
      text: 'role3',
    },
    {
      id: 0,
      text: 'No one',
    },
  ];

  const abilities = {
    adminProject: true,
    adminProtectedBranch: false,
    adminProtectedEnvironments: false,
  };
  const createComponent = ({
    accessLevelsData = mockAccessLevelsData,
    accessLevel = ACCESS_LEVELS.PUSH,
    glAbilities = abilities,
    stubs = {},
    ...optionalProps
  } = {}) => {
    wrapper = shallowMountExtended(AccessDropdown, {
      propsData: {
        accessLevelsData,
        accessLevel,
        ...optionalProps,
      },
      provide: {
        glAbilities,
      },
      stubs: {
        GlSprintf,
        GlDropdown,
        ...stubs,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggleLabel = () => findDropdown().props('text');
  const findAllDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findAllDropdownHeaders = () => findDropdown().findAllComponents(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findDeployKeyDropdownItem = () => wrapper.findByTestId('deploy_key-dropdown-item');

  const findDropdownItemWithText = (items, text) =>
    items.filter((item) => item.text().includes(text)).at(0);

  const findSelected = (type) =>
    wrapper.findAllByTestId(`${type}-dropdown-item`).filter((w) => w.props('isChecked'));

  describe('data request', () => {
    it('should make an api call for users, groups && deployKeys when user has a license', () => {
      createComponent();
      expect(getUsers).toHaveBeenCalled();
      expect(getGroups).toHaveBeenCalledWith({ withProjectAccess: false });
      expect(getDeployKeys).toHaveBeenCalled();
    });

    describe('withProjectAccess', () => {
      it('should make an api call for users, groups && deployKeys when user has a license', () => {
        createComponent({ groupsWithProjectAccess: true });
        expect(getUsers).toHaveBeenCalled();
        expect(getGroups).toHaveBeenCalledWith({ withProjectAccess: true });
        expect(getDeployKeys).toHaveBeenCalled();
      });
    });

    describe('withProtectedBranchesAccess', () => {
      it('should make an api call for users && groups when user has a license', () => {
        createComponent({
          groupsWithProjectAccess: true,
          glAbilities: {
            adminProject: false,
            adminProtectedBranch: true,
            adminProtectedEnvironments: false,
          },
        });
        expect(getUsers).toHaveBeenCalled();
        expect(getGroups).toHaveBeenCalledWith({ withProjectAccess: true });
        expect(getDeployKeys).not.toHaveBeenCalled();
      });
    });

    describe('withProtectedEnvironmentsAccess', () => {
      it('should make an api call for users && groups when user has a license', () => {
        createComponent({
          groupsWithProjectAccess: true,
          glAbilities: {
            adminProject: false,
            adminProtectedBranch: false,
            adminProtectedEnvironments: true,
          },
        });
        expect(getUsers).toHaveBeenCalled();
        expect(getGroups).toHaveBeenCalledWith({ withProjectAccess: true });
        expect(getDeployKeys).not.toHaveBeenCalled();
      });
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
      expect(getGroups).toHaveBeenCalledWith({ withProjectAccess: false });
      expect(getDeployKeys).toHaveBeenCalledWith(query);
    });
  });

  describe('layout', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders headers for each section', () => {
      expect(findAllDropdownHeaders()).toHaveLength(4);
    });

    it('renders dropdown item for each access level type', () => {
      expect(findAllDropdownItems()).toHaveLength(13);
    });

    it.each`
      accessLevel             | shouldRenderDeployKeyItems
      ${ACCESS_LEVELS.PUSH}   | ${true}
      ${ACCESS_LEVELS.CREATE} | ${true}
      ${ACCESS_LEVELS.MERGE}  | ${false}
    `(
      'conditionally renders deploy keys based on access levels',
      async ({ accessLevel, shouldRenderDeployKeyItems }) => {
        createComponent({ accessLevel });
        await waitForPromises();

        expect(findDeployKeyDropdownItem().exists()).toBe(shouldRenderDeployKeyItems);
      },
    );
  });

  describe('toggleLabel', () => {
    let dropdownItems = [];
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      dropdownItems = findAllDropdownItems();
    });

    const findItemByNameAndClick = async (name) => {
      findDropdownItemWithText(dropdownItems, name).trigger('click');
      await nextTick();
    };

    it('when no items selected and custom label provided, displays it and has default CSS class', () => {
      wrapper.destroy();
      const customLabel = 'Set the access level';
      createComponent({ label: customLabel });
      expect(findDropdownToggleLabel()).toBe(customLabel);
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(true);
    });

    it('when no items selected, displays a default fallback label and has default CSS class', () => {
      expect(findDropdownToggleLabel()).toBe(i18n.defaultLabel);
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(true);
    });

    it('displays selected items for each group level', async () => {
      dropdownItems.wrappers.forEach((item) => {
        item.trigger('click');
      });
      await nextTick();
      expect(findDropdownToggleLabel()).toBe('No role, 3 users, 3 deploy keys, 3 groups');
    });

    it('with only role selected displays the role name and has no class applied', async () => {
      await findItemByNameAndClick('role1');
      expect(findDropdownToggleLabel()).toBe('role1');
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(false);
    });

    it('with only groups selected displays the number of selected groups', async () => {
      await findItemByNameAndClick('group4');
      await findItemByNameAndClick('group5');
      await findItemByNameAndClick('group6');
      expect(findDropdownToggleLabel()).toBe('3 groups');
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(false);
    });

    it('with only users selected displays the number of selected users', async () => {
      await findItemByNameAndClick('user7');
      await findItemByNameAndClick('user8');
      expect(findDropdownToggleLabel()).toBe('2 users');
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(false);
    });

    it('with users and groups selected displays the number of selected users & groups', async () => {
      await findItemByNameAndClick('group4');
      await findItemByNameAndClick('group6');
      await findItemByNameAndClick('user7');
      await findItemByNameAndClick('user9');
      expect(findDropdownToggleLabel()).toBe('2 users, 2 groups');
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(false);
    });

    it('with users and deploy keys selected displays the number of selected users & keys', async () => {
      await findItemByNameAndClick('user8');
      await findItemByNameAndClick('key10');
      await findItemByNameAndClick('key11');
      expect(findDropdownToggleLabel()).toBe('1 user, 2 deploy keys');
      expect(findDropdown().props('toggleClass')[defaultToggleClass]).toBe(false);
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
      // ids: the items appear in that order in the dropdown
      // 1 2 3 - roles
      // 4 5 6 - groups
      // 7 8 9 - users
      // 10 11 12 - deploy_keys
      // we set 2 from each group as preselected. Then for the sake of the test deselect one, leave one as-is
      // and select a new one from the group.
      // Preselected items should have `id` along with `user_id/group_id/access_level/deplo_key_id`.
      // Items to be removed from previous selection will have `_deploy` flag set to true
      // Newly selected items will have only `user_id/group_id/access_level/deploy_key_id` (depending on their type);
      const preselectedItems = [
        { id: 112, type: 'role', access_level: 2 },
        { id: 113, type: 'role', access_level: 3 },
        { id: 115, type: 'group', group_id: 5 },
        { id: 116, type: 'group', group_id: 6 },
        { id: 118, type: 'user', user_id: 8, name: 'user8' },
        { id: 119, type: 'user', user_id: 9, name: 'user9' },
        { id: 121, type: 'deploy_key', deploy_key_id: 11 },
        { id: 122, type: 'deploy_key', deploy_key_id: 12 },
      ];

      createComponent({ preselectedItems });
      await waitForPromises();
      const dropdownItems = findAllDropdownItems();
      // select new item from each group
      findDropdownItemWithText(dropdownItems, 'role1').trigger('click');
      findDropdownItemWithText(dropdownItems, 'group4').trigger('click');
      findDropdownItemWithText(dropdownItems, 'user7').trigger('click');
      findDropdownItemWithText(dropdownItems, 'key10').trigger('click');
      // deselect one item from each group
      findDropdownItemWithText(dropdownItems, 'role2').trigger('click');
      findDropdownItemWithText(dropdownItems, 'group5').trigger('click');
      findDropdownItemWithText(dropdownItems, 'user8').trigger('click');
      findDropdownItemWithText(dropdownItems, 'key11').trigger('click');

      expect(last(wrapper.emitted('select'))[0]).toStrictEqual([
        { access_level: 1 },
        { id: 112, access_level: 2, _destroy: true },
        { id: 113, access_level: 3 },
        { group_id: 4 },
        { id: 115, group_id: 5, _destroy: true },
        { id: 116, group_id: 6 },
        { user_id: 7 },
        { id: 118, user_id: 8, _destroy: true },
        { id: 119, user_id: 9 },
        { deploy_key_id: 10 },
        { id: 121, deploy_key_id: 11, _destroy: true },
        { id: 122, deploy_key_id: 12 },
      ]);
    });
  });

  describe('Handling preselected items', () => {
    const preselectedItems = [
      { id: 112, type: 'role', access_level: 2 },
      { id: 115, type: 'group', group_id: 5 },
      { id: 118, type: 'user', user_id: 8, name: 'user2' },
      { id: 121, type: 'deploy_key', deploy_key_id: 11 },
      { id: 122, type: 'deploy_key', deploy_key_id: 12 },
    ];

    beforeEach(async () => {
      createComponent({ preselectedItems });
      await waitForPromises();
    });

    it('should set selected roles as intersection between the server response and preselected', () => {
      const selectedRoles = findSelected(LEVEL_TYPES.ROLE);
      expect(selectedRoles).toHaveLength(1);
      expect(selectedRoles.at(0).text()).toBe('role2');
    });

    it('should set selected groups as intersection between the server response and preselected', () => {
      const selectedGroups = findSelected(LEVEL_TYPES.GROUP);
      expect(selectedGroups).toHaveLength(1);
      expect(selectedGroups.at(0).text()).toBe('group5');
    });

    it('should set selected users to all preselected mapping `user_id` to `id`', () => {
      const selectedUsers = findSelected(LEVEL_TYPES.USER);
      expect(selectedUsers).toHaveLength(1);
      expect(selectedUsers.at(0).text()).toBe('user2');
    });

    it('should set selected deploy keys as intersection between the server response and preselected mapping some keys', () => {
      const selectedDeployKeys = findSelected(LEVEL_TYPES.DEPLOY_KEY);
      expect(selectedDeployKeys).toHaveLength(2);
      expect(selectedDeployKeys.at(0).text()).toContain('key11 (sha256-abcdefg...)');
      expect(selectedDeployKeys.at(1).text()).toContain('key12 (md5-abcdefghij...)');
    });
  });

  describe('handling two-way data binding', () => {
    it('emits a formatted update on selection', async () => {
      createComponent();
      await waitForPromises();
      const dropdownItems = findAllDropdownItems();
      // select new item from each group
      findDropdownItemWithText(dropdownItems, 'role1').trigger('click');
      findDropdownItemWithText(dropdownItems, 'group4').trigger('click');
      findDropdownItemWithText(dropdownItems, 'user7').trigger('click');
      findDropdownItemWithText(dropdownItems, 'key10').trigger('click');

      await wrapper.setProps({ items: [{ user_id: 7 }] });

      const selectedUsers = findSelected(LEVEL_TYPES.USER);
      expect(selectedUsers).toHaveLength(1);
      expect(selectedUsers.at(0).text()).toBe('user7');

      const selectedRoles = findSelected(LEVEL_TYPES.ROLE);
      expect(selectedRoles).toHaveLength(0);

      const selectedGroups = findSelected(LEVEL_TYPES.GROUP);
      expect(selectedGroups).toHaveLength(0);

      const selectedDeployKeys = findSelected(LEVEL_TYPES.DEPLOY_KEY);
      expect(selectedDeployKeys).toHaveLength(0);
    });
  });

  describe('on dropdown open', () => {
    const focusInput = jest.fn();

    beforeEach(() => {
      createComponent({
        stubs: {
          GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
            methods: { focusInput },
          }),
        },
      });
    });

    it('should set the search input focus', () => {
      findDropdown().vm.$emit('shown');

      expect(focusInput).toHaveBeenCalled();
    });
  });

  describe('on dropdown close', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should emit `hidden` event with dropdown selection', () => {
      findAllDropdownItems().at(1).trigger('click');

      findDropdown().vm.$emit('hidden');
      expect(wrapper.emitted('hidden')[0][0]).toStrictEqual([{ access_level: 2 }]);
    });
  });

  describe('when no license and accessLevel is MERGE', () => {
    beforeEach(async () => {
      createComponent({ hasLicense: false, accessLevel: ACCESS_LEVELS.MERGE });
      await waitForPromises();
    });

    it('dropdown is single-select', () => {
      const dropdownItems = findAllDropdownItems();

      findDropdownItemWithText(dropdownItems, mockAccessLevelsData[0].text).trigger('click');
      findDropdownItemWithText(dropdownItems, mockAccessLevelsData[1].text).trigger('click');

      expect(wrapper.emitted('select')[1]).toHaveLength(1);
    });
  });

  describe('section expansion observation', () => {
    const setupTest = (isExpanded = false) => {
      setHTMLFixture(`<div id="test-section" class="${isExpanded ? 'expanded' : ''}"></div>`);
      createComponent({ sectionSelector: '#test-section' });
      return nextTick();
    };

    afterEach(() => resetHTMLFixture());

    it('calls getData when section is already expanded', async () => {
      await setupTest(true);

      expect(getUsers).toHaveBeenCalled();
      expect(getGroups).toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalled();
    });

    it('observes section expansion and calls getData when expanded', async () => {
      await setupTest();

      expect(getUsers).not.toHaveBeenCalled();
      expect(getGroups).not.toHaveBeenCalled();
      expect(getDeployKeys).not.toHaveBeenCalled();

      document.getElementById('test-section').classList.add('expanded');
      await nextTick();

      expect(getUsers).toHaveBeenCalled();
      expect(getGroups).toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalled();
    });

    it('does not observe section expansion when sectionSelector is not provided', () => {
      createComponent({ sectionSelector: null });

      expect(getUsers).toHaveBeenCalled();
      expect(getGroups).toHaveBeenCalled();
      expect(getDeployKeys).toHaveBeenCalled();
    });
  });
});
