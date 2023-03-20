import { GlLink, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrWidgetAlertMessage from '~/vue_merge_request_widget/components/mr_widget_alert_message.vue';

let wrapper;

function createComponent(propsData = {}) {
  wrapper = shallowMount(MrWidgetAlertMessage, {
    propsData,
  });
}

describe('MrWidgetAlertMessage', () => {
  it('should render a GlAert', () => {
    createComponent({ type: 'danger' });

    expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
    expect(wrapper.findComponent(GlAlert).props('variant')).toBe('danger');
  });

  describe('when helpPath is not provided', () => {
    it('should not render a help link', () => {
      createComponent({ type: 'info' });

      const link = wrapper.findComponent(GlLink);

      expect(link.exists()).toBe(false);
    });
  });

  describe('when helpPath is provided', () => {
    it('should render a help link', () => {
      createComponent({ type: 'info', helpPath: 'https://gitlab.com' });

      const link = wrapper.findComponent(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('https://gitlab.com');
    });
  });
});
