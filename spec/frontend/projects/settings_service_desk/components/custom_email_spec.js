import { GlButton, GlToggle, GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CustomEmail from '~/projects/settings_service_desk/components/custom_email.vue';
import {
  I18N_STATE_VERIFICATION_STARTED,
  I18N_STATE_VERIFICATION_FAILED,
  I18N_STATE_VERIFICATION_FAILED_RESET_PARAGRAPH,
  I18N_STATE_VERIFICATION_STARTED_RESET_PARAGRAPH,
  I18N_STATE_VERIFICATION_FINISHED_RESET_PARAGRAPH,
} from '~/projects/settings_service_desk/custom_email_constants';

describe('CustomEmail', () => {
  let wrapper;

  const defaultProps = {
    incomingEmail: 'incoming+test-1-issue-@example.com',
    customEmail: 'user@example.com',
    smtpAddress: 'smtp.example.com',
    verificationState: 'started',
    verificationError: null,
    enabled: false,
    submitting: false,
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findToggle = () => wrapper.findComponent(GlToggle);

  const createWrapper = (props = {}) => {
    wrapper = mount(CustomEmail, { propsData: { ...defaultProps, ...props } });
  };

  it('displays the custom email address and smtp address in the body', () => {
    createWrapper();
    const text = wrapper.text();

    expect(text).toContain(defaultProps.customEmail);
    expect(text).toContain(defaultProps.smtpAddress);
  });

  describe('when verificationState is started', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays badge with correct props', () => {
      expect(findBadge().props('variant')).toBe('info');
      expect(findBadge().text()).toBe(I18N_STATE_VERIFICATION_STARTED);
    });

    it('displays reset paragraph', () => {
      expect(wrapper.text()).toContain(I18N_STATE_VERIFICATION_STARTED_RESET_PARAGRAPH);
    });
  });

  describe('when verificationState is failed', () => {
    beforeEach(() => {
      createWrapper({ verificationState: 'failed' });
    });

    it('displays badge with correct props', () => {
      expect(findBadge().props('variant')).toBe('danger');
      expect(findBadge().text()).toBe(I18N_STATE_VERIFICATION_FAILED);
    });

    it('displays reset paragraph', () => {
      expect(wrapper.text()).toContain(I18N_STATE_VERIFICATION_FAILED_RESET_PARAGRAPH);
    });
  });

  describe('verification error', () => {
    it.each`
      error                                   | label                                                 | description
      ${'smtp_host_issue'}                    | ${'SMTP host issue'}                                  | ${'A connection to the specified host could not be made or an SSL issue occurred.'}
      ${'invalid_credentials'}                | ${'Invalid credentials'}                              | ${'The given credentials (username and password) were rejected by the SMTP server, or you need to explicitly set an authentication method.'}
      ${'mail_not_received_within_timeframe'} | ${'Verification email not received within timeframe'} | ${"The verification email wasn't received in time. There is a 30 minutes timeframe for verification emails to appear in your instance's Service Desk. Make sure that you have set up email forwarding correctly."}
      ${'incorrect_from'}                     | ${'Incorrect From header'}                            | ${'Check your forwarding settings and make sure the original email sender remains in the From header.'}
      ${'incorrect_token'}                    | ${'Incorrect verification token'}                     | ${"The received email didn't contain the verification token that was sent to your email address."}
      ${'read_timeout'}                       | ${'Read timeout'}                                     | ${'The SMTP server did not respond in time.'}
      ${'incorrect_forwarding_target'}        | ${'Incorrect forwarding target'}                      | ${`Forward all emails to the custom email address to ${defaultProps.incomingEmail}`}
    `('displays $error label and description', ({ error, label, description }) => {
      createWrapper({ verificationError: error });
      const text = wrapper.text();

      expect(text).toContain(label);
      expect(text).toContain(description);
    });
  });

  describe('when verificationState is finished', () => {
    beforeEach(() => {
      createWrapper({ verificationState: 'finished' });
    });

    it('displays reset paragraph', () => {
      expect(wrapper.text()).toContain(I18N_STATE_VERIFICATION_FINISHED_RESET_PARAGRAPH);
    });

    it('toggle value is false', () => {
      expect(findToggle().props('value')).toBe(false);
    });

    it('emits a toggle event when toggle is clicked', async () => {
      findToggle().vm.$emit('change', true);
      await nextTick();

      expect(wrapper.emitted('toggle')).toEqual([[true]]);
    });
  });

  describe('when enabled', () => {
    beforeEach(() => {
      createWrapper({ verificationState: 'finished', isEnabled: true });
    });

    it('value is true', () => {
      expect(findToggle().props('value')).toBe(true);
    });
  });

  describe('button', () => {
    it('emits a reset event when button clicked', () => {
      createWrapper();
      findButton().trigger('click');

      expect(wrapper.emitted('reset')).toEqual([[]]);
    });

    it('does not emit event when button clicked and submitting', () => {
      createWrapper({ isSubmitting: true });
      findButton().trigger('click');

      expect(wrapper.emitted('reset')).toBeUndefined();
    });
  });
});
