import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/vue_merge_request_widget/components/widget/action_buttons.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(Actions, {
    propsData: { ...propsData, widget: 'test' },
  });
}

describe('~/vue_merge_request_widget/components/widget/action_buttons.vue', () => {
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
      factory({
        tertiaryButtons: [{ text: 'hello world', href: 'https://gitlab.com', target: '_blank' }],
      });

      expect(wrapper.findAllComponents(GlDisclosureDropdown)).toHaveLength(1);
    });
  });
});
