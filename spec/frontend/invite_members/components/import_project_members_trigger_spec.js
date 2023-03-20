import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ImportProjectMembersTrigger from '~/invite_members/components/import_project_members_trigger.vue';
import eventHub from '~/invite_members/event_hub';

const displayText = 'Import Project Members';

const createComponent = (props = {}) => {
  return mount(ImportProjectMembersTrigger, {
    propsData: {
      displayText,
      ...props,
    },
  });
};

describe('ImportProjectMembersTrigger', () => {
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
      expect(eventHub.$emit).toHaveBeenLastCalledWith('openProjectMembersModal');
    });
  });
});
