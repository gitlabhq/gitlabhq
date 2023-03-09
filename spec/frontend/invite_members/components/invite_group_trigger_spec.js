import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import InviteGroupTrigger from '~/invite_members/components/invite_group_trigger.vue';
import eventHub from '~/invite_members/event_hub';

const displayText = 'Invite a group';

const createComponent = (props = {}) => {
  return mount(InviteGroupTrigger, {
    propsData: {
      displayText,
      ...props,
    },
  });
};

describe('InviteGroupTrigger', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  describe('displayText', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('includes the correct displayText for the link', () => {
      expect(findButton().text()).toBe(displayText);
    });
  });

  describe('when button is clicked', () => {
    beforeEach(() => {
      eventHub.$emit = jest.fn();

      wrapper = createComponent();

      findButton().trigger('click');
    });

    it('emits event that triggers opening the modal', () => {
      expect(eventHub.$emit).toHaveBeenLastCalledWith('openGroupModal');
    });
  });
});
