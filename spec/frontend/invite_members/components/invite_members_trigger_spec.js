import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlLink } from '@gitlab/ui';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

const displayText = 'Invite team members';
const icon = 'plus';

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
    const findLink = () => wrapper.find(GlLink);

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('includes the correct displayText for the link', () => {
      expect(findLink().text()).toBe(displayText);
    });
  });

  describe('icon', () => {
    const findIcon = () => wrapper.find(GlIcon);

    it('includes the correct icon when an icon is sent', () => {
      wrapper = createComponent({ icon });

      expect(findIcon().attributes('name')).toBe(icon);
    });

    it('does not include an icon when icon is not sent', () => {
      wrapper = createComponent();

      expect(findIcon().exists()).toBe(false);
    });

    it('does not include an icon when empty string is sent', () => {
      wrapper = createComponent({ icon: '' });

      expect(findIcon().exists()).toBe(false);
    });
  });
});
