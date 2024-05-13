import { shallowMount } from '@vue/test-utils';
import AccessRequestActionButtons from '~/members/components/action_buttons/access_request_action_buttons.vue';
import ApproveAccessRequestButton from '~/members/components/action_buttons/approve_access_request_button.vue';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';
import { accessRequest as member } from '../../mock_data';

describe('AccessRequestActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}, provide = {}) => {
    wrapper = shallowMount(AccessRequestActionButtons, {
      propsData: {
        member,
        isCurrentUser: true,
        ...propsData,
      },
      provide: {
        canApproveAccessRequests: true,
        ...provide,
      },
    });
  };

  const findRemoveMemberButton = () => wrapper.findComponent(RemoveMemberButton);
  const findApproveButton = () => wrapper.findComponent(ApproveAccessRequestButton);

  it('renders remove member button', () => {
    createComponent();

    expect(findRemoveMemberButton().exists()).toBe(true);
  });

  it('sets props correctly on remove member button', () => {
    createComponent();

    expect(findRemoveMemberButton().props()).toMatchObject({
      memberId: member.id,
      title: 'Deny access',
      isAccessRequest: true,
      isInvite: false,
    });
  });

  describe('when member is the current user', () => {
    it('sets `message` prop correctly', () => {
      createComponent();

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

  it('renders the approve button', () => {
    createComponent();

    expect(findApproveButton().exists()).toBe(true);
  });
});
