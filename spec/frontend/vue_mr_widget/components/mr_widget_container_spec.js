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

  afterEach(() => {
    wrapper.destroy();
  });

  it('has layout', () => {
    factory();

    expect(wrapper.is('.mr-widget-heading')).toBe(true);
    expect(wrapper.contains('.mr-widget-content')).toBe(true);
  });

  it('accepts default slot', () => {
    factory({
      slots: {
        default: BODY_HTML,
      },
    });

    expect(wrapper.contains('.mr-widget-content .test-body')).toBe(true);
  });

  it('accepts footer slot', () => {
    factory({
      slots: {
        default: BODY_HTML,
        footer: FOOTER_HTML,
      },
    });

    expect(wrapper.contains('.mr-widget-content .test-body')).toBe(true);
    expect(wrapper.contains('.test-footer')).toBe(true);
  });
});
