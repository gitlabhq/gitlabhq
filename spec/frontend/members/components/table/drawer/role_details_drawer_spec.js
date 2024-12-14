import { GlDrawer, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoleDetailsDrawer from '~/members/components/table/drawer/role_details_drawer.vue';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import RoleSelector from '~/members/components/role_selector.vue';
import { roleDropdownItems } from '~/members/utils';
import RoleUpdater from 'ee_else_ce/members/components/table/drawer/role_updater.vue';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import { member as memberData, updateableMember } from '../../../mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => '123',
}));

describe('Role details drawer', () => {
  const dropdownItems = roleDropdownItems(updateableMember);
  const currentRole = dropdownItems.flatten.find(
    (role) => role.accessLevel === updateableMember.accessLevel.integerValue,
  );
  const newRole = dropdownItems.flatten[2];
  const saveRoleStub = jest.fn();
  let wrapper;

  const createWrapper = ({ member = updateableMember } = {}) => {
    wrapper = shallowMountExtended(RoleDetailsDrawer, {
      propsData: { member },
      stubs: {
        GlDrawer: stubComponent(GlDrawer, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        RoleUpdater: stubComponent(RoleUpdater, {
          template: '<div><slot :save-role="saveRole"></slot></div>',
          methods: { saveRole: saveRoleStub },
        }),
        MembersTableCell: stubComponent(MembersTableCell, {
          render() {
            return this.$scopedSlots.default({
              memberType: 'user',
              isCurrentUser: false,
              permissions: { canUpdate: member.canUpdate },
            });
          },
        }),
      },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findRoleText = () => wrapper.findByTestId('role-text');
  const findRoleSelector = () => wrapper.findComponent(RoleSelector);
  const findRoleDescription = () => wrapper.findByTestId('description-value');
  const findRoleUpdater = () => wrapper.findComponent(RoleUpdater);
  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createWrapperAndChangeRole = () => {
    createWrapper();
    findRoleSelector().vm.$emit('input', newRole);

    return nextTick;
  };

  it('does not show the drawer when there is no member', () => {
    createWrapper({ member: null });

    expect(findDrawer().exists()).toBe(false);
  });

  describe('when there is a member', () => {
    beforeEach(createWrapper);

    it('shows the drawer', () => {
      expect(findDrawer().props()).toMatchObject({
        headerHeight: '123',
        headerSticky: true,
        open: true,
        zIndex: 252,
      });
    });

    it('shows the user avatar', () => {
      expect(wrapper.findComponent(MembersTableCell).props('member')).toBe(updateableMember);
      expect(wrapper.findComponent(MemberAvatar).props()).toEqual({
        memberType: 'user',
        isCurrentUser: false,
        member: updateableMember,
      });
    });

    describe('role name', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('role-header').text()).toBe('Role');
      });
    });

    describe('role description', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('description-header').text()).toBe('Description');
      });

      it('shows the role description', () => {
        expect(findRoleDescription().text()).toBe(updateableMember.accessLevel.description);
      });
    });

    describe('role permissions', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('permissions-header').text()).toBe('Permissions');
      });

      it('shows the View permissions button', () => {
        const button = wrapper.findByTestId('view-permissions-button');

        expect(button.text()).toBe('View permissions');
        expect(button.attributes('href')).toBe('/help/user/permissions');
        expect(button.props()).toMatchObject({
          icon: 'external-link',
          variant: 'link',
          target: '_blank',
        });
      });
    });
  });

  describe('role name/selector', () => {
    it('shows role name when the member cannot be edited', () => {
      createWrapper({ member: memberData });

      expect(findRoleText().text()).toBe('Owner');
      expect(findRoleSelector().exists()).toBe(false);
    });

    it('shows role selector when member can be edited', () => {
      createWrapper({ member: updateableMember });

      expect(findRoleText().exists()).toBe(false);
      expect(findRoleSelector().props()).toMatchObject({
        roles: dropdownItems,
        value: currentRole,
        loading: false,
      });
    });
  });

  describe('when role is changed', () => {
    beforeEach(createWrapperAndChangeRole);

    it('shows role updater', () => {
      expect(findRoleUpdater().props()).toEqual({ member: updateableMember, role: newRole });
    });

    it('shows save button', () => {
      expect(findSaveButton().text()).toBe('Update role');
      expect(findSaveButton().props()).toMatchObject({ variant: 'confirm', loading: false });
    });

    it('shows cancel button', () => {
      expect(findCancelButton().text()).toBe('Cancel');
      expect(findCancelButton().props()).toMatchObject({ variant: 'default', loading: false });
    });

    it('shows the new role in the role selector', () => {
      expect(findRoleSelector().props('value')).toBe(newRole);
    });
  });

  describe('when cancel button is clicked', () => {
    beforeEach(createWrapperAndChangeRole);

    it('resets back to initial role', async () => {
      findCancelButton().vm.$emit('click');
      await nextTick();

      expect(findRoleSelector().props('value')).toEqual(currentRole);
    });
  });

  describe('when update role button is clicked', () => {
    it('calls saveRole method on the role updater', async () => {
      await createWrapperAndChangeRole();
      findSaveButton().vm.$emit('click');

      expect(saveRoleStub).toHaveBeenCalledTimes(1);
    });
  });

  describe('role updater', () => {
    beforeEach(createWrapperAndChangeRole);

    describe.each([true, false])('when busy event is %s', (busy) => {
      beforeEach(() => {
        findRoleUpdater().vm.$emit('busy', busy);
      });

      it('sets loading on role selector', () => {
        expect(findRoleSelector().props('loading')).toBe(busy);
      });

      it('sets loading on save button', () => {
        expect(findSaveButton().props('loading')).toBe(busy);
      });

      it('sets disabled on cancel button', () => {
        expect(findCancelButton().props('disabled')).toBe(busy);
      });
    });

    // This needs to be a separate test from the describe.each() block above because watchers aren't invoked if the
    // value didn't change, so setting the busy state to false when it's already false will cause the test to fail.
    // Here, we'll set it to true first, then false, which changes the value both times, thus invoking the watcher.
    it('emits busy event when loading state is changed', async () => {
      findRoleUpdater().vm.$emit('busy', true);
      await nextTick();

      expect(wrapper.emitted('busy')[0][0]).toBe(true);

      findRoleUpdater().vm.$emit('busy', false);
      await nextTick();

      expect(wrapper.emitted('busy')[1][0]).toBe(false);
    });

    it('resets the selected role on a reset event', async () => {
      await createWrapperAndChangeRole();
      findRoleUpdater().vm.$emit('reset');
      await nextTick();

      expect(findRoleSelector().props('value')).toEqual(currentRole);
    });
  });

  describe('alert', () => {
    beforeEach(async () => {
      await createWrapperAndChangeRole();
      findRoleUpdater().vm.$emit('alert', {
        message: 'alert message',
        variant: 'info',
        dismissible: false,
      });
    });

    it('shows an alert when role updater changes the alert', () => {
      expect(findAlert().text()).toBe('alert message');
      expect(findAlert().props()).toMatchObject({ variant: 'info', dismissible: false });
    });

    it('keeps alert when role updater resets selected role', async () => {
      // Some workflows treat a role reset as a success. We shouldn't clear the alert in this case because it would
      // clear out the success message.
      findRoleUpdater().vm.$emit('reset');
      await nextTick();

      expect(findAlert().exists()).toBe(true);
    });

    it.each`
      phrase                                          | setupFn
      ${'when the role updater emits an empty alert'} | ${() => findRoleUpdater().vm.$emit('alert', null)}
      ${'when selected role is changed'}              | ${() => findRoleSelector().vm.$emit('input', currentRole)}
      ${'when drawer is closed'}                      | ${() => findDrawer().vm.$emit('close')}
      ${'when member is changed'}                     | ${() => wrapper.setProps({ member: memberData })}
      ${'when alert is dismissed'}                    | ${() => findAlert().vm.$emit('dismiss')}
    `('clears alert when $phrase', async ({ setupFn }) => {
      setupFn();
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when drawer is closing', () => {
    it('emits close event', () => {
      createWrapper();
      findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('does not allow the drawer to close when the role is saving', async () => {
      await createWrapperAndChangeRole();
      findRoleUpdater().vm.$emit('busy', true);
      findDrawer().vm.$emit('close');
      await nextTick();

      expect(wrapper.emitted('close')).toBeUndefined();
    });
  });
});
