import { shallowMount } from '@vue/test-utils';
import LeaveButton from '~/members/components/action_buttons/leave_button.vue';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';
import UserActionButtons from '~/members/components/action_buttons/user_action_buttons.vue';
import { member, orphanedMember } from '../../mock_data';

describe('UserActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(UserActionButtons, {
      propsData: {
        member,
        isCurrentUser: false,
        ...propsData,
      },
    });
  };

  const findRemoveMemberButton = () => wrapper.find(RemoveMemberButton);

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

    it('renders remove member button', () => {
      expect(findRemoveMemberButton().exists()).toBe(true);
    });

    it('sets props correctly', () => {
      expect(findRemoveMemberButton().props()).toEqual({
        memberId: member.id,
        memberType: 'GroupMember',
        message: `Are you sure you want to remove ${member.user.name} from "${member.source.fullName}"?`,
        title: 'Remove member',
        isAccessRequest: false,
        isInvite: false,
        icon: 'remove',
        oncallSchedules: {
          name: member.user.name,
          schedules: member.user.oncallSchedules,
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

        expect(findRemoveMemberButton().props('message')).toBe(
          `Are you sure you want to remove this orphaned member from "${orphanedMember.source.fullName}"?`,
        );
      });
    });

    describe('when member is the current user', () => {
      it('renders leave button', () => {
        createComponent({
          isCurrentUser: true,
          permissions: {
            canRemove: true,
          },
        });

        expect(wrapper.find(LeaveButton).exists()).toBe(true);
      });
    });
  });

  describe('when user does not have `canRemove` permissions', () => {
    it('does not render remove member button', () => {
      createComponent({
        permissions: {
          canRemove: false,
        },
      });

      expect(findRemoveMemberButton().exists()).toBe(false);
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
      expect(findRemoveMemberButton().props().memberType).toBe('GroupMember');
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
      expect(findRemoveMemberButton().props().memberType).toBe('ProjectMember');
    });
  });
});
