import { mount } from '@vue/test-utils';
import { isExperimentVariant } from '~/experimentation/utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { INVITE_MEMBERS_IN_COMMENT } from '~/invite_members/constants';
import Toolbar from '~/vue_shared/components/markdown/toolbar.vue';

jest.mock('~/experimentation/utils', () => ({ isExperimentVariant: jest.fn() }));

describe('toolbar', () => {
  let wrapper;

  const createMountedWrapper = (props = {}) => {
    wrapper = mount(Toolbar, {
      propsData: { markdownDocsPath: '', ...props },
      stubs: { 'invite-members-trigger': true },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    isExperimentVariant.mockReset();
  });

  describe('user can attach file', () => {
    beforeEach(() => {
      createMountedWrapper();
    });

    it('should render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).not.toBeNull();
    });
  });

  describe('user cannot attach file', () => {
    beforeEach(() => {
      createMountedWrapper({ canAttachFile: false });
    });

    it('should not render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).toBeNull();
    });
  });

  describe('user can invite member', () => {
    const findInviteLink = () => wrapper.find(InviteMembersTrigger);

    beforeEach(() => {
      isExperimentVariant.mockReturnValue(true);
      createMountedWrapper();
    });

    it('should render the invite members trigger', () => {
      expect(findInviteLink().exists()).toBe(true);
    });

    it('should have correct props', () => {
      expect(findInviteLink().props().displayText).toBe('Invite Member');
      expect(findInviteLink().props().trackExperiment).toBe(INVITE_MEMBERS_IN_COMMENT);
      expect(findInviteLink().props().triggerSource).toBe(INVITE_MEMBERS_IN_COMMENT);
    });
  });

  describe('user can not invite member', () => {
    const findInviteLink = () => wrapper.find(InviteMembersTrigger);

    beforeEach(() => {
      isExperimentVariant.mockReturnValue(false);
      createMountedWrapper();
    });

    it('should render the invite members trigger', () => {
      expect(findInviteLink().exists()).toBe(false);
    });
  });
});
