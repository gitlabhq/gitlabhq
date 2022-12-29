import { shallowMount } from '@vue/test-utils';
import { sprintf } from '~/locale';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LeaveGroupDropdownItem from '~/members/components/action_dropdowns/leave_group_dropdown_item.vue';
import RemoveMemberDropdownItem from '~/members/components/action_dropdowns/remove_member_dropdown_item.vue';
import UserActionDropdown from '~/members/components/action_dropdowns/user_action_dropdown.vue';
import { I18N } from '~/members/components/action_dropdowns/constants';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import { member, orphanedMember } from '../../mock_data';

describe('UserActionDropdown', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(UserActionDropdown, {
      propsData: {
        member,
        isCurrentUser: false,
        isInvitedUser: false,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findRemoveMemberDropdownItem = () => wrapper.findComponent(RemoveMemberDropdownItem);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when user has `canRemove` permissions', () => {
    beforeEach(() => {
      createComponent({
        permissions: {
          canRemove: true,
        },
      });
    });

    it('renders remove member dropdown with correct text', () => {
      const removeMemberDropdownItem = findRemoveMemberDropdownItem();
      expect(removeMemberDropdownItem.exists()).toBe(true);
      expect(removeMemberDropdownItem.html()).toContain(I18N.removeMember);
    });

    it('displays a tooltip', () => {
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip).not.toBeUndefined();
      expect(tooltip.value).toBe(I18N.actions);
    });

    it('sets props correctly', () => {
      expect(findRemoveMemberDropdownItem().props()).toEqual({
        memberId: member.id,
        memberType: 'GroupMember',
        modalMessage: sprintf(
          I18N.confirmNormalUserRemoval,
          {
            userName: member.user.name,
            group: member.source.fullName,
          },
          false,
        ),
        isAccessRequest: false,
        isInvite: false,
        userDeletionObstacles: {
          name: member.user.name,
          obstacles: parseUserDeletionObstacles(member.user),
        },
      });
    });

    describe('when member is orphaned', () => {
      it('sets `message` prop correctly', () => {
        createComponent({
          member: orphanedMember,
          permissions: {
            canRemove: true,
          },
        });

        expect(findRemoveMemberDropdownItem().props('modalMessage')).toBe(
          sprintf(I18N.confirmOrphanedUserRemoval, { group: orphanedMember.source.fullName }),
        );
      });
    });

    describe('when member is the current user', () => {
      it('renders leave dropdown with correct text', () => {
        createComponent({
          isCurrentUser: true,
          permissions: {
            canRemove: true,
          },
        });

        const leaveGroupDropdownItem = wrapper.findComponent(LeaveGroupDropdownItem);
        expect(leaveGroupDropdownItem.exists()).toBe(true);
        expect(leaveGroupDropdownItem.html()).toContain(I18N.leaveGroup);
      });
    });
  });

  describe('when user does not have `canRemove` permissions', () => {
    it('does not render remove member dropdown', () => {
      createComponent({
        permissions: {
          canRemove: false,
        },
      });

      expect(findRemoveMemberDropdownItem().exists()).toBe(false);
    });
  });

  describe('when group member', () => {
    beforeEach(() => {
      createComponent({
        member: {
          ...member,
          type: 'GroupMember',
        },
        permissions: {
          canRemove: true,
        },
      });
    });

    it('sets member type correctly', () => {
      expect(findRemoveMemberDropdownItem().props().memberType).toBe('GroupMember');
    });
  });

  describe('when project member', () => {
    beforeEach(() => {
      createComponent({
        member: {
          ...member,
          type: 'ProjectMember',
        },
        permissions: {
          canRemove: true,
        },
      });
    });

    it('sets member type correctly', () => {
      expect(findRemoveMemberDropdownItem().props().memberType).toBe('ProjectMember');
    });
  });
});
