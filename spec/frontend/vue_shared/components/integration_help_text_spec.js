import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

describe('IntegrationHelpText component', () => {
  let wrapper;
  const defaultProps = {
    message: 'Click %{linkStart}Bar%{linkEnd}!',
    messageUrl: 'http://bar.com',
  };

  function createComponent(props = {}) {
    return shallowMount(IntegrationHelpText, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should use the gl components', () => {
    wrapper = createComponent();

    expect(wrapper.find(GlSprintf).exists()).toBe(true);
    expect(wrapper.find(GlIcon).exists()).toBe(true);
    expect(wrapper.find(GlLink).exists()).toBe(true);
  });

  it('should render the help text', () => {
    wrapper = createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should not use the gl-link and gl-icon components', () => {
    wrapper = createComponent({ message: 'Click nowhere!' });

    expect(wrapper.find(GlSprintf).exists()).toBe(true);
    expect(wrapper.find(GlIcon).exists()).toBe(false);
    expect(wrapper.find(GlLink).exists()).toBe(false);
  });

  it('should not render the link when start and end is not provided', () => {
    wrapper = createComponent({ message: 'Click nowhere!' });

    expect(wrapper.element).toMatchSnapshot();
  });
});
