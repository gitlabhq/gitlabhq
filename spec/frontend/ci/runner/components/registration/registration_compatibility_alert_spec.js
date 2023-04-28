import { GlAlert, GlLink } from '@gitlab/ui';
import DismissibleFeedbackAlert from '~/vue_shared/components/dismissible_feedback_alert.vue';
import RegistrationCompatibilityAlert from '~/ci/runner/components/registration/registration_compatibility_alert.vue';
import { CHANGELOG_URL } from '~/ci/runner/constants';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

const ALERT_KEY = 'ALERT_KEY';

describe('RegistrationCompatibilityAlert', () => {
  let wrapper;

  const findDismissibleFeedbackAlert = () => wrapper.findComponent(DismissibleFeedbackAlert);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RegistrationCompatibilityAlert, {
      propsData: {
        alertKey: ALERT_KEY,
      },
      ...options,
    });
  };

  it('configures a featureName', () => {
    createComponent();

    expect(findDismissibleFeedbackAlert().props('featureName')).toBe(
      `new_runner_compatibility_${ALERT_KEY}`,
    );
  });

  it('alert has warning appearance', () => {
    createComponent({
      stubs: {
        DismissibleFeedbackAlert,
      },
    });

    expect(findAlert().props()).toMatchObject({
      dismissible: true,
      variant: 'warning',
      title: expect.any(String),
    });
  });

  it('shows alert content and link', () => {
    createComponent({ mountFn: mountExtended });

    expect(findAlert().text()).not.toBe('');
    expect(findLink().attributes('href')).toBe(CHANGELOG_URL);
  });
});
