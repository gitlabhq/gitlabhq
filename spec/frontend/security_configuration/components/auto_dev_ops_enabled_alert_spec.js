import { GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AutoDevopsEnabledAlert from '~/security_configuration/components/auto_dev_ops_enabled_alert.vue';

const autoDevopsHelpPagePath = '/autoDevopsHelpPagePath';

describe('AutoDevopsEnabledAlert component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(AutoDevopsEnabledAlert, {
      provide: {
        autoDevopsHelpPagePath,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    createComponent();
  });

  it('contains correct body text', () => {
    expect(wrapper.text()).toMatchInterpolatedText(AutoDevopsEnabledAlert.i18n.body);
  });

  it('renders the link correctly', () => {
    const link = wrapper.find('a[href]');

    expect(link.attributes('href')).toBe(autoDevopsHelpPagePath);
    expect(link.text()).toBe('Auto DevOps');
  });

  it('bubbles up dismiss events from the GlAlert', () => {
    expect(wrapper.emitted('dismiss')).toBe(undefined);

    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });
});
