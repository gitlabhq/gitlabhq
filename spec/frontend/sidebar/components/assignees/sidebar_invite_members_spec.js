import { shallowMount } from '@vue/test-utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';

describe('Sidebar invite members component', () => {
  let wrapper;

  const findDirectInviteLink = () => wrapper.findComponent(InviteMembersTrigger);
  const findHelpText = () => wrapper.find('p');

  const createComponent = (issuableType = 'issue') => {
    wrapper = shallowMount(SidebarInviteMembers, {
      propsData: {
        issuableType,
      },
    });
  };

  describe('when directly inviting members', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a direct link to project members path', () => {
      expect(findDirectInviteLink().exists()).toBe(true);
    });

    it('has expected attributes on the trigger', () => {
      expect(findDirectInviteLink().props('triggerSource')).toBe('issue_assignee_dropdown');
    });
  });

  describe('invite help text', () => {
    it('renders help text for non-merge-request issuable types', () => {
      createComponent('issue');

      expect(findHelpText().text()).toBe('Invite members to plan and track work.');
    });

    it('renders help text for merge request issuable type', () => {
      createComponent('merge_request');

      expect(findHelpText().text()).toBe(
        'Invite members to collaborate on changes to the repository.',
      );
    });
  });
});
