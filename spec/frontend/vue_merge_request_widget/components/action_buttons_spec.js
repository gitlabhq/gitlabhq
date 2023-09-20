import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/vue_merge_request_widget/components/action_buttons.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(Actions, {
    propsData,
  });
}

describe('MR widget extension actions', () => {
  describe('tertiaryButtons', () => {
    it('renders buttons', () => {
      factory({
        tertiaryButtons: [{ text: 'hello world', href: 'https://gitlab.com', target: '_blank' }],
      });

      expect(wrapper.findAllComponents(GlButton)).toHaveLength(1);
    });

    it('calls action click handler', async () => {
      const onClick = jest.fn();

      factory({
        tertiaryButtons: [{ text: 'hello world', onClick }],
      });

      await wrapper.findComponent(GlButton).vm.$emit('click');

      expect(onClick).toHaveBeenCalled();
    });

    it('renders tertiary actions in dropdown', () => {
      const action = { text: 'hello world', href: 'https://gitlab.com', target: '_blank' };
      factory({
        tertiaryButtons: [action, action],
      });

      const component = wrapper.findComponent(GlDisclosureDropdown);
      expect(component.exists()).toBe(true);
      expect(component.props('items')).toMatchObject([
        {
          text: action.text,
          href: action.href,
          extraAttrs: {
            target: action.target,
          },
        },
        {
          text: action.text,
          href: action.href,
          extraAttrs: {
            target: action.target,
          },
        },
      ]);
    });
  });
});
