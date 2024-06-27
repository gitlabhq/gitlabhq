import { GlDrawer, GlSprintf, GlAlert } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoleDetailsDrawer from '~/members/components/table/drawer/role_details_drawer.vue';
import MembersTableCell from '~/members/components/table/members_table_cell.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import RoleSelector from '~/members/components/table/drawer/role_selector.vue';
import { roleDropdownItems } from '~/members/utils';
import waitForPromises from 'helpers/wait_for_promises';
import { member as memberData, updateableMember } from '../../mock_data';

describe('Role details drawer', () => {
  const dropdownItems = roleDropdownItems(updateableMember);
  const toastShowMock = jest.fn();
  const role1 = dropdownItems.flatten[4];
  const role2 = dropdownItems.flatten[2];
  let axiosMock;
  let wrapper;

  const createWrapper = ({ member = updateableMember, namespace = 'user' } = {}) => {
    wrapper = shallowMountExtended(RoleDetailsDrawer, {
      propsData: { member, memberPath: 'user/path/:id' },
      provide: {
        currentUserId: 1,
        canManageMembers: true,
        namespace,
        group: 'group/path',
      },
      stubs: { GlDrawer, MembersTableCell, GlSprintf },
      mocks: { $toast: { show: toastShowMock } },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findRoleText = () => wrapper.findByTestId('role-text');
  const findRoleSelector = () => wrapper.findComponent(RoleSelector);
  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  const createWrapperChangeRoleAndClickSave = async () => {
    createWrapper({ member: cloneDeep(updateableMember) });
    findRoleSelector().vm.$emit('input', role2);
    await nextTick();
    findSaveButton().vm.$emit('click');

    return waitForPromises();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('does not show the drawer when there is no member', () => {
    createWrapper({ member: null });

    expect(findDrawer().exists()).toBe(false);
  });

  describe('when there is a member', () => {
    beforeEach(() => {
      createWrapper({ member: memberData });
    });

    it('shows the drawer with expected props', () => {
      expect(findDrawer().props()).toMatchObject({ headerSticky: true, open: true, zIndex: 252 });
    });

    it('shows the user avatar', () => {
      expect(wrapper.findComponent(MembersTableCell).props('member')).toBe(memberData);
      expect(wrapper.findComponent(MemberAvatar).props()).toMatchObject({
        memberType: 'user',
        isCurrentUser: false,
        member: memberData,
      });
    });

    it('does not show footer buttons', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    it('emits close event when drawer is closed', () => {
      findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    describe('role name', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('role-header').text()).toBe('Role');
      });

      it('shows the role name', () => {
        expect(findRoleText().text()).toContain('Owner');
      });
    });

    describe('permissions', () => {
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

  describe('role selector', () => {
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
        value: role1,
        loading: false,
      });
    });
  });

  describe('when the user only has read access', () => {
    it('shows the custom role name', () => {
      const member = {
        ...memberData,
        accessLevel: { stringValue: 'Custom role', memberRoleId: 102 },
      };
      createWrapper({ member });

      expect(findRoleText().text()).toBe('Custom role');
    });
  });

  describe('when role is changed', () => {
    beforeEach(() => {
      createWrapper();
      findRoleSelector().vm.$emit('input', role2);
    });

    it('shows save button', () => {
      expect(findSaveButton().text()).toBe('Update role');
      expect(findSaveButton().props()).toMatchObject({
        variant: 'confirm',
        loading: false,
      });
    });

    it('shows cancel button', () => {
      expect(findCancelButton().props('variant')).toBe('default');
      expect(findCancelButton().props()).toMatchObject({
        variant: 'default',
        loading: false,
      });
    });

    it('shows the new role in the role selector', () => {
      expect(findRoleSelector().props('value')).toBe(role2);
    });

    it('does not call update role API', () => {
      expect(axiosMock.history.put).toHaveLength(0);
    });

    it('does not emit any events', () => {
      expect(Object.keys(wrapper.emitted())).toHaveLength(0);
    });

    it('resets back to initial role when cancel button is clicked', async () => {
      findCancelButton().vm.$emit('click');
      await nextTick();

      expect(findRoleSelector().props('value')).toEqual(role1);
    });
  });

  describe('when update role button is clicked', () => {
    beforeEach(() => {
      axiosMock.onPut('user/path/238').replyOnce(200);
      createWrapperChangeRoleAndClickSave();

      return nextTick();
    });

    it('calls update role API with expected data', () => {
      const expectedData = JSON.stringify({ access_level: 30, member_role_id: null });

      expect(axiosMock.history.put[0].data).toBe(expectedData);
    });

    it('disables footer buttons', () => {
      expect(findSaveButton().props('loading')).toBe(true);
      expect(findCancelButton().props('disabled')).toBe(true);
    });

    it('disables role dropdown', () => {
      expect(findRoleSelector().props('loading')).toBe(true);
    });

    it('emits busy event as true', () => {
      const busyEvents = wrapper.emitted('busy');

      expect(busyEvents).toHaveLength(1);
      expect(busyEvents[0][0]).toBe(true);
    });

    it('does not close the drawer when it is trying to close', () => {
      findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toBeUndefined();
    });
  });

  describe('when update role API call is finished', () => {
    beforeEach(() => {
      axiosMock.onPut('user/path/238').replyOnce(200);
      return createWrapperChangeRoleAndClickSave();
    });

    it('hides footer buttons', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    it('enables role selector', () => {
      expect(findRoleSelector().props('loading')).toBe(false);
    });

    it('emits busy event with false', () => {
      const busyEvents = wrapper.emitted('busy');

      expect(busyEvents).toHaveLength(2);
      expect(busyEvents[1][0]).toBe(false);
    });

    it('shows toast', () => {
      expect(toastShowMock).toHaveBeenCalledTimes(1);
      expect(toastShowMock).toHaveBeenCalledWith('Role was successfully updated.');
    });
  });

  describe('when role admin approval is enabled and role is updated', () => {
    beforeEach(() => {
      axiosMock.onPut('user/path/238').replyOnce(200, { enqueued: true });
      return createWrapperChangeRoleAndClickSave();
    });

    it('resets role back to initial role', () => {
      expect(findRoleSelector().props('value')).toEqual(role1);
    });

    it('shows toast', () => {
      expect(toastShowMock).toHaveBeenCalledTimes(1);
      expect(toastShowMock).toHaveBeenCalledWith(
        'Role change request was sent to the administrator.',
      );
    });
  });

  describe('when update role API fails', () => {
    beforeEach(() => {
      axiosMock.onPut('user/path/238').replyOnce(500);
      return createWrapperChangeRoleAndClickSave();
    });

    it('enables save and cancel buttons', () => {
      expect(findSaveButton().props('loading')).toBe(false);
      expect(findCancelButton().props('disabled')).toBe(false);
    });

    it('enables role dropdown', () => {
      expect(findRoleSelector().props('loading')).toBe(false);
    });

    it('emits busy event with false', () => {
      const busyEvents = wrapper.emitted('busy');

      expect(busyEvents).toHaveLength(2);
      expect(busyEvents[1][0]).toBe(false);
    });

    it('shows error message', () => {
      const alert = wrapper.findComponent(GlAlert);

      expect(alert.text()).toBe('Could not update role.');
      expect(alert.props('variant')).toBe('danger');
    });
  });
});
