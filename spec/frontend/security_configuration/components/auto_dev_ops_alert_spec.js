import { GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AutoDevopsAlert from '~/security_configuration/components/auto_dev_ops_alert.vue';

const autoDevopsHelpPagePath = '/autoDevopsHelpPagePath';
const autoDevopsPath = '/enableAutoDevopsPath';

describe('AutoDevopsAlert component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(AutoDevopsAlert, {
      provide: {
        autoDevopsHelpPagePath,
        autoDevopsPath,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains correct body text', () => {
    expect(wrapper.text()).toContain('Quickly enable all');
  });

  it('renders the link correctly', () => {
    const link = wrapper.find('a');

    expect(link.attributes('href')).toBe(autoDevopsHelpPagePath);
    expect(link.text()).toBe('Auto DevOps');
  });

  it('bubbles up dismiss events from the GlAlert', () => {
    expect(wrapper.emitted('dismiss')).toBe(undefined);

    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });

  it('has a button pointing to autoDevopsPath', () => {
    expect(findAlert().props()).toMatchObject({
      primaryButtonText: 'Enable Auto DevOps',
      primaryButtonLink: autoDevopsPath,
    });
  });
});
