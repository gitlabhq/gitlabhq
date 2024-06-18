import { shallowMount } from '@vue/test-utils';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';

const BODY_HTML = '<div class="test-body">Hello World</div>';
const FOOTER_HTML = '<div class="test-footer">Goodbye!</div>';

describe('MrWidgetContainer', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(MrWidgetContainer, {
      ...options,
    });
  };

  it('has layout', () => {
    factory();

    expect(wrapper.classes()).toContain('mr-section-container');
    expect(wrapper.find('.mr-widget-content').exists()).toBe(true);
  });

  it('accepts default slot', () => {
    factory({
      slots: {
        default: BODY_HTML,
      },
    });

    expect(wrapper.find('.mr-widget-content .test-body').exists()).toBe(true);
  });

  it('accepts footer slot', () => {
    factory({
      slots: {
        default: BODY_HTML,
        footer: FOOTER_HTML,
      },
    });

    expect(wrapper.find('.mr-widget-content .test-body').exists()).toBe(true);
    expect(wrapper.find('.test-footer').exists()).toBe(true);
  });
});
