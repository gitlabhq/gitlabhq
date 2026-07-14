import { nextTick } from 'vue';
import { GlDrawer, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import AccessLevelsDrawer from '~/projects/settings/branch_rules/components/access_levels_drawer.vue';
import {
  allowedToMergeDrawerProps,
  editRuleData,
  editRuleDataNoAccessLevels,
  editRuleDataNoOne,
  customRolesMock,
} from 'ee_else_ce_jest/projects/settings/branch_rules/components/mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

const TEST_HEADER_HEIGHT = '123px';

describe('Edit Access Levels Drawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findCancelButton = () => wrapper.findByTestId('cancel-btn');
  const findHeader = () => wrapper.find('h2');
  const findSaveButton = () => wrapper.findByTestId('save-allowed-to-merge');
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findAdministratorsCheckbox = () => wrapper.findByTestId('admins-role-checkbox');
  const findMaintainersCheckbox = () => wrapper.findByTestId('maintainers-role-checkbox');
  const findDevelopersAndMaintainersCheckbox = () =>
    wrapper.findByTestId('developers-role-checkbox');
  const findNoOneCheckbox = () => wrapper.findByTestId('no-one-role-checkbox');

  const createComponent = (props = allowedToMergeDrawerProps) => {
    wrapper = shallowMountExtended(AccessLevelsDrawer, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    window.gon.dot_com = false;
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    createComponent();
  });

  describe('rendering', () => {
    it('renders the correct title when adding', () => {
      expect(findHeader().text()).toBe('Edit allowed to merge');
    });

    it('renders drawer with props', () => {
      expect(findDrawer().props()).toMatchObject({
        open: false,
        headerHeight: TEST_HEADER_HEIGHT,
        zIndex: DRAWER_Z_INDEX,
      });
    });
  });

  it('disables the save button when no changes are made', () => {
    expect(findSaveButton().attributes('disabled')).toBeDefined();
  });

  it('emits an edit rule event when save button is clicked', () => {
    findSaveButton().vm.$emit('click');
    expect(wrapper.emitted('editRule')).toHaveLength(1);
  });

  it('emits a close event when cancel button is clicked', () => {
    findCancelButton().vm.$emit('click');
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('renders checkboxes with expected text', () => {
    expect(findCheckboxes()).toHaveLength(4);
    expect(findAdministratorsCheckbox().text()).toBe('Administrators');
    expect(findMaintainersCheckbox().text()).toBe('Maintainers');
    expect(findDevelopersAndMaintainersCheckbox().text()).toBe('Developers and Maintainers');
    expect(findNoOneCheckbox().text()).toBe('No one');
  });

  it('emits expected data', () => {
    findAdministratorsCheckbox().vm.$emit('input', true);
    findMaintainersCheckbox().vm.$emit('input', true);
    findDevelopersAndMaintainersCheckbox().vm.$emit('input', true);
    findSaveButton().vm.$emit('click');

    expect(wrapper.emitted('editRule')).toHaveLength(1);
    expect(wrapper.emitted('editRule')[0][0]).toEqual(editRuleData);
  });

  it('when `No one` is selected, it sets other access level checkboxes to false', async () => {
    createComponent({ ...allowedToMergeDrawerProps, roles: [30, 40, 60], isOpen: true });
    findNoOneCheckbox().vm.$emit('input', true);
    await nextTick();

    expect(findAdministratorsCheckbox().attributes('checked')).toBeUndefined();
    expect(findMaintainersCheckbox().attributes('checked')).toBeUndefined();
    expect(findDevelopersAndMaintainersCheckbox().attributes('checked')).toBeUndefined();
    expect(findNoOneCheckbox().attributes('checked')).toBe('true');
  });

  it('when `No one` is initially selected, selecting another role unchecks `No one', async () => {
    createComponent({ ...allowedToMergeDrawerProps, roles: [0], isOpen: true });
    findAdministratorsCheckbox().vm.$emit('input', true);
    await nextTick();

    expect(findNoOneCheckbox().attributes('checked')).toBeUndefined();
    expect(findAdministratorsCheckbox().attributes('checked')).toBe('true');
  });

  it('when all roles are checked it sends `No one` as a role', () => {
    findAdministratorsCheckbox().vm.$emit('input', true);
    findMaintainersCheckbox().vm.$emit('input', true);
    findDevelopersAndMaintainersCheckbox().vm.$emit('input', true);
    findNoOneCheckbox().vm.$emit('input', true);

    findSaveButton().vm.$emit('click');
    expect(wrapper.emitted('editRule')).toHaveLength(1);
    expect(wrapper.emitted('editRule')[0][0]).toEqual(editRuleDataNoOne);
  });

  it('when all roles are unchecked it does not send any role', () => {
    findAdministratorsCheckbox().vm.$emit('input', false);
    findMaintainersCheckbox().vm.$emit('input', false);
    findDevelopersAndMaintainersCheckbox().vm.$emit('input', false);
    findNoOneCheckbox().vm.$emit('input', false);

    findSaveButton().vm.$emit('click');
    expect(wrapper.emitted('editRule')[0][0]).toEqual(editRuleDataNoAccessLevels);
  });

  describe('for dot_com', () => {
    beforeEach(() => {
      gon.dot_com = true;
      getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
      createComponent();
    });

    it('does not render a checkbox for Administrators', () => {
      expect(findCheckboxes()).toHaveLength(3);
      expect(findAdministratorsCheckbox().exists()).toBe(false);
    });
  });

  describe('custom role selection', () => {
    // Minimal props: no users/groups/deployKeys so the emitted payload only
    // contains what each test explicitly sets.
    const minimalProps = {
      isLoading: false,
      isOpen: false,
      title: 'Edit allowed to merge',
      roles: [],
      users: [],
      groups: [],
      deployKeys: [],
    };

    // savedMemberRoles: GlobalID form as returned by the EE GraphQL query.
    // Reuse the shared fixture (id + name only — the fields the CE drawer cares about).
    const savedMemberRoles = customRolesMock.map(({ id, name }) => ({ id, name }));

    const openDrawer = async () => {
      wrapper.setProps({ isOpen: true });
      await nextTick();
    };

    it('includes memberRoleId entries in the editRule payload when custom roles are selected', async () => {
      createComponent(minimalProps);
      // handleCustomRolesSelected is the slot's on-change handler; calling it
      // directly is the only way to drive the ee-custom-roles slot in shallowMount.
      wrapper.vm.handleCustomRolesSelected([1, 2]);
      await nextTick();

      findSaveButton().vm.$emit('click');

      expect(wrapper.emitted('editRule')[0][0]).toEqual(
        expect.arrayContaining([
          { memberRoleId: 'gid://gitlab/MemberRole/1' },
          { memberRoleId: 'gid://gitlab/MemberRole/2' },
        ]),
      );
    });

    it('places memberRoleId entries before plain accessLevel entries in the payload', async () => {
      createComponent(minimalProps);
      wrapper.vm.handleCustomRolesSelected([1]);
      findMaintainersCheckbox().vm.$emit('input', true);
      await nextTick();

      findSaveButton().vm.$emit('click');

      const emitted = wrapper.emitted('editRule')[0][0];
      expect(emitted.findIndex((e) => e.memberRoleId !== undefined)).toBeLessThan(
        emitted.findIndex((e) => e.accessLevel !== undefined),
      );
    });

    it('does not include a plain accessLevel for a custom-role-only selection', async () => {
      createComponent(minimalProps);
      wrapper.vm.handleCustomRolesSelected([1]);
      await nextTick();

      findSaveButton().vm.$emit('click');

      expect(wrapper.emitted('editRule')[0][0]).toEqual([
        { memberRoleId: 'gid://gitlab/MemberRole/1' },
      ]);
    });

    it('preselects saved custom roles from memberRoles prop when drawer opens', async () => {
      createComponent({ ...minimalProps, memberRoles: savedMemberRoles });
      await openDrawer();

      // Verify preselection via the emitted payload (integer ids → GlobalIDs).
      findSaveButton().vm.$emit('click');
      expect(wrapper.emitted('editRule')[0][0]).toEqual(
        expect.arrayContaining([
          { memberRoleId: 'gid://gitlab/MemberRole/1' },
          { memberRoleId: 'gid://gitlab/MemberRole/2' },
        ]),
      );
    });

    it('clears custom role selection when No one is selected', async () => {
      createComponent({ ...minimalProps, memberRoles: savedMemberRoles });
      await openDrawer();

      // Emit both `input` (v-model) and `change` (@change handler) to fully simulate a checkbox click.
      findNoOneCheckbox().vm.$emit('input', true);
      findNoOneCheckbox().vm.$emit('change', true);
      await nextTick();

      findSaveButton().vm.$emit('click');
      const emitted = wrapper.emitted('editRule')[0][0];
      expect(emitted.some((e) => e.memberRoleId !== undefined)).toBe(false);
      expect(emitted).toEqual([{ accessLevel: 0 }]);
    });

    it('restores saved custom roles when drawer is reopened after deselection', async () => {
      createComponent({ ...minimalProps, memberRoles: savedMemberRoles });
      await openDrawer();

      // Deselect all custom roles
      wrapper.vm.handleCustomRolesSelected([]);
      await nextTick();

      // Close and reopen — watcher should restore saved state
      wrapper.setProps({ isOpen: false });
      await nextTick();
      await openDrawer();

      findSaveButton().vm.$emit('click');
      expect(wrapper.emitted('editRule')[0][0]).toEqual(
        expect.arrayContaining([
          { memberRoleId: 'gid://gitlab/MemberRole/1' },
          { memberRoleId: 'gid://gitlab/MemberRole/2' },
        ]),
      );
    });
  });
});
