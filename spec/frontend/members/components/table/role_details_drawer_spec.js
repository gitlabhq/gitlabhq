import { GlDrawer, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoleDetailsDrawer from '~/members/components/table/role_details_drawer.vue';
import MembersTableCell from '~/members/components/table/members_table_cell.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import { member as memberData } from '../../mock_data';

describe('Role details drawer', () => {
  let wrapper;

  const createWrapper = ({ member = memberData } = {}) => {
    wrapper = shallowMountExtended(RoleDetailsDrawer, {
      propsData: { member },
      provide: { currentUserId: memberData.user.id, canManageMembers: false },
      stubs: { MembersTableCell },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  it('does not show the drawer when there is no member selected', () => {
    createWrapper({ member: null });

    expect(findDrawer().exists()).toBe(false);
  });

  describe('when there is a member', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the drawer with expected props', () => {
      expect(findDrawer().props()).toMatchObject({ headerSticky: true, open: true, zIndex: 252 });
    });

    it('shows the user avatar', () => {
      expect(wrapper.findComponent(MembersTableCell).props('member')).toBe(memberData);
      expect(wrapper.findComponent(MemberAvatar).props()).toMatchObject({
        memberType: 'user',
        isCurrentUser: true,
        member: memberData,
      });
    });

    describe('Role name', () => {
      it('shows the header', () => {
        expect(wrapper.findByTestId('role-header').text()).toBe('Role');
      });

      it('shows the role name', () => {
        expect(wrapper.findByTestId('role-value').text()).toBe('Owner');
      });
    });

    describe('Permissions', () => {
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
});
