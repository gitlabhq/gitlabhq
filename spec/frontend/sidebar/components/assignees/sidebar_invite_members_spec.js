import { shallowMount } from '@vue/test-utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';

describe('Sidebar invite members component', () => {
  let wrapper;

  const findDirectInviteLink = () => wrapper.findComponent(InviteMembersTrigger);

  const createComponent = () => {
    wrapper = shallowMount(SidebarInviteMembers);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when directly inviting members', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a direct link to project members path', () => {
      expect(findDirectInviteLink().exists()).toBe(true);
    });
  });
});
