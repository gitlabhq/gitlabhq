import { shallowMount } from '@vue/test-utils';
import InviteActionButtons from '~/members/components/action_buttons/invite_action_buttons.vue';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';
import ResendInviteButton from '~/members/components/action_buttons/resend_invite_button.vue';
import { invite as member } from '../../mock_data';

describe('InviteActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(InviteActionButtons, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const findRemoveMemberButton = () => wrapper.findComponent(RemoveMemberButton);
  const findResendInviteButton = () => wrapper.findComponent(ResendInviteButton);

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
      expect(findRemoveMemberButton().props()).toMatchObject({
        memberId: member.id,
        message: `Are you sure you want to revoke the invitation for ${member.invite.email} to join "${member.source.fullName}"`,
        title: 'Revoke invite',
        isAccessRequest: false,
        isInvite: true,
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

  describe('when user has `canResend` permissions', () => {
    it('renders resend invite button', () => {
      createComponent({
        permissions: {
          canResend: true,
        },
      });

      expect(findResendInviteButton().exists()).toBe(true);
    });
  });

  describe('when user does not have `canResend` permissions', () => {
    it('does not render resend invite button', () => {
      createComponent({
        permissions: {
          canResend: false,
        },
      });

      expect(findResendInviteButton().exists()).toBe(false);
    });
  });
});
