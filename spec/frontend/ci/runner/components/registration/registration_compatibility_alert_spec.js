import { GlAlert, GlLink } from '@gitlab/ui';
import RegistrationCompatibilityAlert from '~/ci/runner/components/registration/registration_compatibility_alert.vue';
import { CHANGELOG_URL } from '~/ci/runner/constants';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

describe('RegistrationCompatibilityAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = (mountFn = shallowMountExtended) => {
    wrapper = mountFn(RegistrationCompatibilityAlert);
  };

  it('alert has warning appearance', () => {
    createComponent();

    expect(findAlert().props()).toMatchObject({
      dismissible: false,
      variant: 'warning',
      title: expect.any(String),
    });
  });

  it('shows alert content and link', () => {
    createComponent(mountExtended);

    expect(findAlert().text()).not.toBe('');
    expect(findLink().attributes('href')).toBe(CHANGELOG_URL);
  });
});
