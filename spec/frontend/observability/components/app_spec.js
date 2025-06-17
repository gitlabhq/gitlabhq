import { shallowMount } from '@vue/test-utils';
import App from '~/observability/components/app.vue';

describe('Observability App Component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(App, {
      propsData: {
        o11yUrl: 'https://o11y.gitlab.com',
        path: 'traces-explorer',
        ...props,
      },
    });
  };

  it('renders the iframe with correct attributes', () => {
    wrapper = createComponent();

    const iframe = wrapper.find('iframe');
    expect(iframe.exists()).toBe(true);
    expect(iframe.attributes('title')).toBe('Observability Dashboard');
    expect(iframe.attributes('frameborder')).toBe('0');
    expect(iframe.classes()).toContain('gl-h-full');
    expect(iframe.classes()).toContain('gl-w-full');
  });

  it('computes the correct iframe URL', () => {
    wrapper = createComponent({
      o11yUrl: 'https://o11y.gitlab.com',
      path: 'traces-explorer',
    });

    expect(wrapper.find('iframe').attributes('src')).toBe(
      'https://o11y.gitlab.com/traces-explorer',
    );
  });

  it('handles paths with leading slashes correctly', () => {
    wrapper = createComponent({
      o11yUrl: 'https://o11y.gitlab.com',
      path: '/dashboard',
    });

    expect(wrapper.find('iframe').attributes('src')).toBe('https://o11y.gitlab.com/dashboard');
  });

  it('handles nested paths correctly', () => {
    wrapper = createComponent({
      o11yUrl: 'https://o11y.gitlab.com',
      path: 'logs/logs-explorer',
    });

    expect(wrapper.find('iframe').attributes('src')).toBe(
      'https://o11y.gitlab.com/logs/logs-explorer',
    );
  });
});
