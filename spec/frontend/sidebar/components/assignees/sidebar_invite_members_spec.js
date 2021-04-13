import { shallowMount } from '@vue/test-utils';
import InviteMemberModal from '~/invite_member/components/invite_member_modal.vue';
import InviteMemberTrigger from '~/invite_member/components/invite_member_trigger.vue';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';

const testProjectMembersPath = 'test-path';

describe('Sidebar invite members component', () => {
  let wrapper;

  const findDirectInviteLink = () => wrapper.findComponent(InviteMembersTrigger);
  const findIndirectInviteLink = () => wrapper.findComponent(InviteMemberTrigger);
  const findInviteModal = () => wrapper.findComponent(InviteMemberModal);

  const createComponent = ({ directlyInviteMembers = false } = {}) => {
    wrapper = shallowMount(SidebarInviteMembers, {
      provide: {
        directlyInviteMembers,
        projectMembersPath: testProjectMembersPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when directly inviting members', () => {
    beforeEach(() => {
      createComponent({ directlyInviteMembers: true });
    });

    it('renders a direct link to project members path', () => {
      expect(findDirectInviteLink().exists()).toBe(true);
    });

    it('does not render invite members trigger and modal components', () => {
      expect(findIndirectInviteLink().exists()).toBe(false);
      expect(findInviteModal().exists()).toBe(false);
    });
  });

  describe('when indirectly inviting members', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render a direct link to project members path', () => {
      expect(findDirectInviteLink().exists()).toBe(false);
    });

    it('does not render invite members trigger and modal components', () => {
      expect(findIndirectInviteLink().exists()).toBe(true);
      expect(findInviteModal().exists()).toBe(true);
      expect(findInviteModal().props('membersPath')).toBe(testProjectMembersPath);
    });
  });
});
