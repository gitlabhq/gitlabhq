import { shallowMount } from '@vue/test-utils';
import AccessRequestActionButtons from '~/members/components/action_buttons/access_request_action_buttons.vue';
import ApproveAccessRequestButton from '~/members/components/action_buttons/approve_access_request_button.vue';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';
import { accessRequest as member } from '../../mock_data';

describe('AccessRequestActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(AccessRequestActionButtons, {
      propsData: {
        member,
        isCurrentUser: true,
        ...propsData,
      },
    });
  };

  const findRemoveMemberButton = () => wrapper.find(RemoveMemberButton);
  const findApproveButton = () => wrapper.find(ApproveAccessRequestButton);

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
      expect(findRemoveMemberButton().props()).toMatchObject({
        memberId: member.id,
        title: 'Deny access',
        isAccessRequest: true,
        isInvite: false,
        icon: 'close',
      });
    });

    describe('when member is the current user', () => {
      it('sets `message` prop correctly', () => {
        expect(findRemoveMemberButton().props('message')).toBe(
          `Are you sure you want to withdraw your access request for "${member.source.fullName}"`,
        );
      });
    });

    describe('when member is not the current user', () => {
      it('sets `message` prop correctly', () => {
        createComponent({
          isCurrentUser: false,
          permissions: {
            canRemove: true,
          },
        });

        expect(findRemoveMemberButton().props('message')).toBe(
          `Are you sure you want to deny ${member.user.name}'s request to join "${member.source.fullName}"`,
        );
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

  describe('when user has `canUpdate` permissions', () => {
    it('renders the approve button', () => {
      createComponent({
        permissions: {
          canUpdate: true,
        },
      });

      expect(findApproveButton().exists()).toBe(true);
    });
  });

  describe('when user does not have `canUpdate` permissions', () => {
    it('does not render the approve button', () => {
      createComponent({
        permissions: {
          canUpdate: false,
        },
      });

      expect(findApproveButton().exists()).toBe(false);
    });
  });
});
