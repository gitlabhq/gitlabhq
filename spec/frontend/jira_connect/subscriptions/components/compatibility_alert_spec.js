import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import CompatibilityAlert from '~/jira_connect/subscriptions/components/compatibility_alert.vue';

import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('CompatibilityAlert', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(CompatibilityAlert);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays an alert', () => {
    createComponent();

    expect(findAlert().exists()).toBe(true);
  });

  it('renders help link with target="_blank" and rel="noopener noreferrer"', () => {
    createComponent({ mountFn: mount });
    expect(findLink().attributes()).toMatchObject({
      target: '_blank',
      rel: 'noopener noreferrer',
    });
  });

  it('`local-storage-sync` value prop is initially false', () => {
    createComponent();

    expect(findLocalStorageSync().props('value')).toBe(false);
  });

  describe('when dismissed', () => {
    beforeEach(async () => {
      createComponent();
      await findAlert().vm.$emit('dismiss');
    });

    it('hides alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('updates value prop of `local-storage-sync`', () => {
      expect(findLocalStorageSync().props('value')).toBe(true);
    });
  });
});
