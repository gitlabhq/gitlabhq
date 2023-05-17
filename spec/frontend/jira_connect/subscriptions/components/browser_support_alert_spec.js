import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import BrowserSupportAlert from '~/jira_connect/subscriptions/components/browser_support_alert.vue';

describe('BrowserSupportAlert', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(BrowserSupportAlert);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  it('displays a non-dismissible alert', () => {
    createComponent();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().props()).toMatchObject({
      dismissible: false,
      title: BrowserSupportAlert.i18n.title,
      variant: 'danger',
    });
  });

  it('renders help link with target="_blank" and rel="noopener noreferrer"', () => {
    createComponent({ mountFn: mount });
    expect(findLink().attributes()).toMatchObject({
      target: '_blank',
      rel: 'noopener',
    });
  });
});
