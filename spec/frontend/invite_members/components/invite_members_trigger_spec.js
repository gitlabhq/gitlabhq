import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

const displayText = 'Invite team members';

const createComponent = (props = {}) => {
  return shallowMount(InviteMembersTrigger, {
    propsData: {
      displayText,
      ...props,
    },
  });
};

describe('InviteMembersTrigger', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('displayText', () => {
    const findButton = () => wrapper.findComponent(GlButton);

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('includes the correct displayText for the button', () => {
      expect(findButton().text()).toBe(displayText);
    });
  });
});
