import { shallowMount } from '@vue/test-utils';
import { sprintf } from '~/locale';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LeaveDropdownItem from '~/members/components/action_dropdowns/leave_dropdown_item.vue';
import RemoveMemberDropdownItem from '~/members/components/action_dropdowns/remove_member_dropdown_item.vue';
import UserActionDropdown from '~/members/components/action_dropdowns/user_action_dropdown.vue';
import { I18N } from '~/members/components/action_dropdowns/constants';
import {
  MEMBER_MODEL_TYPE_GROUP_MEMBER,
  MEMBER_MODEL_TYPE_PROJECT_MEMBER,
} from '~/members/constants';
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
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findRemoveMemberDropdownItem = () => wrapper.findComponent(RemoveMemberDropdownItem);

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
        memberModelType: MEMBER_MODEL_TYPE_GROUP_MEMBER,
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
        preventRemoval: false,
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
      describe('when member is a group member', () => {
        beforeEach(() => {
          createComponent({
            isCurrentUser: true,
            permissions: {
              canRemove: true,
            },
          });
        });

        it('renders leave dropdown with correct text', () => {
          const leaveDropdownItem = wrapper.findComponent(LeaveDropdownItem);
          expect(leaveDropdownItem.exists()).toBe(true);
          expect(leaveDropdownItem.html()).toContain(I18N.leaveGroup);
        });
      });

      describe('when member is a project member', () => {
        beforeEach(() => {
          createComponent({
            member: {
              ...member,
              type: MEMBER_MODEL_TYPE_PROJECT_MEMBER,
            },
            isCurrentUser: true,
            permissions: {
              canRemove: true,
            },
          });
        });

        it('renders leave dropdown with correct text', () => {
          const leaveDropdownItem = wrapper.findComponent(LeaveDropdownItem);
          expect(leaveDropdownItem.exists()).toBe(true);
          expect(leaveDropdownItem.html()).toContain(I18N.leaveProject);
        });
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

  describe('when user can remove but it is blocked by last owner', () => {
    const permissions = {
      canRemove: false,
      canRemoveBlockedByLastOwner: true,
    };

    it('renders remove member dropdown', () => {
      createComponent({
        permissions,
      });

      expect(findRemoveMemberDropdownItem().exists()).toBe(true);
    });

    describe('when member model type is `GroupMember`', () => {
      it('passes correct message to the modal', () => {
        createComponent({
          permissions,
        });

        expect(findRemoveMemberDropdownItem().props('modalMessage')).toBe(
          I18N.lastGroupOwnerCannotBeRemoved,
        );
      });
    });

    describe('when member model type is `ProjectMember`', () => {
      it('passes correct message to the modal', () => {
        createComponent({
          member: {
            ...member,
            type: MEMBER_MODEL_TYPE_PROJECT_MEMBER,
          },
          permissions,
        });

        expect(findRemoveMemberDropdownItem().props('modalMessage')).toBe(
          I18N.personalProjectOwnerCannotBeRemoved,
        );
      });
    });

    describe('when member is the current user', () => {
      it('renders leave dropdown with correct props', () => {
        createComponent({
          isCurrentUser: true,
          permissions,
        });

        expect(wrapper.findComponent(LeaveDropdownItem).props()).toEqual({
          member,
          permissions,
        });
      });
    });
  });

  describe('when group member', () => {
    beforeEach(() => {
      createComponent({
        member: {
          ...member,
          type: MEMBER_MODEL_TYPE_GROUP_MEMBER,
        },
        permissions: {
          canRemove: true,
        },
      });
    });

    it('sets member type correctly', () => {
      expect(findRemoveMemberDropdownItem().props().memberModelType).toBe(
        MEMBER_MODEL_TYPE_GROUP_MEMBER,
      );
    });
  });

  describe('when project member', () => {
    beforeEach(() => {
      createComponent({
        member: {
          ...member,
          type: MEMBER_MODEL_TYPE_PROJECT_MEMBER,
        },
        permissions: {
          canRemove: true,
        },
      });
    });

    it('sets member type correctly', () => {
      expect(findRemoveMemberDropdownItem().props().memberModelType).toBe(
        MEMBER_MODEL_TYPE_PROJECT_MEMBER,
      );
    });
  });
});
