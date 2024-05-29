import { GlDrawer, GlButton, GlBadge, GlSprintf, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoleDetailsDrawer from '~/members/components/table/role_details_drawer.vue';
import MembersTableCell from '~/members/components/table/members_table_cell.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import { member as memberData, memberWithCustomRole } from '../../mock_data';

describe('Role details drawer', () => {
  const { permissions } = memberWithCustomRole.customRoles[0];
  let wrapper;

  const createWrapper = ({ member } = {}) => {
    wrapper = shallowMountExtended(RoleDetailsDrawer, {
      propsData: { member },
      provide: { currentUserId: memberData.user.id, canManageMembers: false },
      stubs: { MembersTableCell, GlSprintf },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findCustomRoleBadge = () => wrapper.findComponent(GlBadge);
  const findDescriptionHeader = () => wrapper.findByTestId('description-header');
  const findDescriptionValue = () => wrapper.findByTestId('description-value');
  const findBaseRole = () => wrapper.findByTestId('base-role');
  const findPermissions = () => wrapper.findAllByTestId('permission');
  const findPermissionAt = (index) => findPermissions().at(index);
  const findPermissionNameAt = (index) => wrapper.findAllByTestId('permission-name').at(index);
  const findPermissionDescriptionAt = (index) =>
    wrapper.findAllByTestId('permission-description').at(index);

  it('does not show the drawer when there is no member selected', () => {
    createWrapper();

    expect(findDrawer().exists()).toBe(false);
  });

  describe.each`
    roleName         | member
    ${'base role'}   | ${memberData}
    ${'custom role'} | ${memberWithCustomRole}
  `(`when there is a member (common tests for $roleName)`, ({ member }) => {
    beforeEach(() => {
      createWrapper({ member });
    });

    it('shows the drawer with expected props', () => {
      expect(findDrawer().props()).toMatchObject({ headerSticky: true, open: true, zIndex: 252 });
    });

    it('shows the user avatar', () => {
      expect(wrapper.findComponent(MembersTableCell).props('member')).toBe(member);
      expect(wrapper.findComponent(MemberAvatar).props()).toMatchObject({
        memberType: 'user',
        isCurrentUser: true,
        member,
      });
    });

    describe('role name', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('role-header').text()).toBe('Role');
      });

      it('shows the role name', () => {
        expect(wrapper.findByTestId('role-value').text()).toContain('Owner');
      });
    });

    describe('permissions', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('permissions-header').text()).toBe('Permissions');
      });

      it('shows the View permissions link', () => {
        const link = wrapper.findComponent(GlButton);

        expect(link.text()).toBe('View permissions');
        expect(link.attributes('href')).toBe('/help/user/permissions');
        expect(link.props()).toMatchObject({
          icon: 'external-link',
          variant: 'link',
          target: '_blank',
        });
      });
    });
  });

  describe('when the member has a base role', () => {
    beforeEach(() => {
      createWrapper({ member: memberData });
    });

    it('does not show the custom role badge', () => {
      expect(findCustomRoleBadge().exists()).toBe(false);
    });

    it('does not show the role description', () => {
      expect(findDescriptionHeader().exists()).toBe(false);
      expect(findDescriptionValue().exists()).toBe(false);
    });

    it('does not show the base role', () => {
      expect(findBaseRole().exists()).toBe(false);
    });

    it('does not show any permissions', () => {
      expect(findPermissions()).toHaveLength(0);
    });
  });

  describe('when the member has a custom role', () => {
    beforeEach(() => {
      createWrapper({ member: memberWithCustomRole });
    });

    it('shows the custom role badge', () => {
      expect(findCustomRoleBadge().props('size')).toBe('sm');
      expect(findCustomRoleBadge().text()).toBe('Custom role');
    });

    it('shows the role description', () => {
      expect(findDescriptionHeader().text()).toBe('Description');
      expect(findDescriptionValue().text()).toBe('Custom role description');
    });

    it('shows the base role', () => {
      expect(findBaseRole().text()).toMatchInterpolatedText('Base role: Owner');
    });

    it('shows the expected number of permissions', () => {
      expect(findPermissions()).toHaveLength(2);
    });

    describe.each(permissions)(`for permission '$name'`, (permission) => {
      const index = permissions.indexOf(permission);

      it('shows the check icon', () => {
        expect(findPermissionAt(index).findComponent(GlIcon).props('name')).toBe('check');
      });

      it('shows the permission name', () => {
        expect(findPermissionNameAt(index).text()).toBe(`Permission ${index}`);
      });

      it('shows the permission description', () => {
        expect(findPermissionDescriptionAt(index).text()).toBe(`Permission description ${index}`);
      });
    });
  });
});
