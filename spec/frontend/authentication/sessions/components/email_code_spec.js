import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlFormFields } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import EmailCode from '~/authentication/sessions/components/email_code.vue';
import EmailForm from '~/sessions/new/components/email_form.vue';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));
jest.mock('~/alert');

describe('EmailCode', () => {
  let wrapper;
  let axiosMock;

  const sendEmailOtpPath = '/users/fallback_to_email_otp';
  const verifyPath = '/users/sign_in';
  const resendPath = '/users/resend_verification_code';

  const defaultProps = {
    sendEmailOtpPath,
    emailVerificationData: {
      obfuscatedEmail: 't***@example.com',
      verifyPath,
      resendPath,
      username: 'testuser',
    },
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(EmailCode, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findVerifyCodeForm = () => wrapper.findByTestId('verify-code-form');
  const findCodeField = () => wrapper.findByTestId('email-code-field');
  const findFormFields = () => wrapper.findComponent(GlFormFields);
  const findVerifyButton = () => wrapper.findByTestId('verify-code-button');
  const findResendButton = () => wrapper.findComponentByTestId('resend-button');
  const findCountdown = () => wrapper.findComponent(GlCountdown);
  const findUseAnotherEmailButton = () => wrapper.findByTestId('use-another-email-button');
  const findBackToSignInButton = () => wrapper.findByTestId('back-to-sign-in-button');
  const findEmailForm = () => wrapper.findComponent(EmailForm);

  const enterCode = (code) => findFormFields().vm.$emit('input', { verificationCode: code });
  const submitCodeForm = () => findFormFields().vm.$emit('submit');

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onPost(sendEmailOtpPath).reply(HTTP_STATUS_OK, { show_resend_after: null });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('on mount', () => {
    it('renders the title and the obfuscated email', () => {
      createComponent();

      expect(wrapper.text()).toContain('Authenticate with your email');
      expect(wrapper.text()).toContain('t***@example.com');
    });

    it('auto-sends a code to the primary email', async () => {
      createComponent();
      await waitForPromises();

      expect(axiosMock.history.post).toHaveLength(1);
      expect(axiosMock.history.post[0].url).toBe(sendEmailOtpPath);
      expect(JSON.parse(axiosMock.history.post[0].data)).toEqual({ user: { login: 'testuser' } });
    });

    it('renders the code form', () => {
      createComponent();

      expect(findVerifyCodeForm().exists()).toBe(true);
      expect(findCodeField().attributes('inputmode')).toBe('numeric');
      expect(findCodeField().attributes('maxlength')).toBe('6');
    });

    it('opts the code field out of password-manager autofill without dropping one-time-code', () => {
      createComponent();

      // The field is a one-time code, so it stays annotated as one for the browser's own
      // autofill; only the extensions that would offer a stored TOTP are opted out.
      expect(findCodeField().attributes('autocomplete')).toBe('one-time-code');
      expect(findCodeField().attributes('data-1p-ignore')).toBe('true');
      expect(findCodeField().attributes('data-bwignore')).toBe('true');
      expect(findCodeField().attributes('data-form-type')).toBe('other');
      expect(findCodeField().attributes('data-lpignore')).toBe('true');
    });

    it('opts the verify button out of the global auto-disable-on-submit behavior', () => {
      createComponent();

      // main.js disables submit buttons on submit; GlFormFields blocks navigation on an
      // invalid or failed submit, so without this opt-out the button stays disabled forever.
      expect(findVerifyButton().classes()).toContain('js-no-auto-disable');
    });

    it('shows a generic alert when auto-send fails with no server message', async () => {
      axiosMock.onPost(sendEmailOtpPath).reply(HTTP_STATUS_UNPROCESSABLE_ENTITY);
      createComponent();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Something went wrong. Please try again.' }),
      );
    });

    it("shows the server's message when auto-send fails with one", async () => {
      const serverMessage =
        'Email verification is no longer available for this sign-in attempt. Log in again.';
      axiosMock
        .onPost(sendEmailOtpPath)
        .reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, { success: false, message: serverMessage });
      createComponent();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: serverMessage });
    });
  });

  describe('back to sign-in', () => {
    it('links to the sign-in page', () => {
      createComponent();

      expect(findBackToSignInButton().attributes('href')).toBe(newUserSessionPath());
    });
  });

  describe('verifying the code', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('posts the token and visits the redirect path on success', async () => {
      axiosMock
        .onPost(verifyPath)
        .reply(HTTP_STATUS_OK, { status: 'success', redirect_path: '/welcome' });

      await enterCode('123456');
      await submitCodeForm();
      await waitForPromises();

      const verifyRequest = axiosMock.history.post.find((req) => req.url === verifyPath);
      expect(JSON.parse(verifyRequest.data)).toEqual({
        user: { verification_token: '123456' },
      });
      expect(visitUrl).toHaveBeenCalledWith('/welcome');
    });

    it('shows the server error message when verification fails', async () => {
      axiosMock
        .onPost(verifyPath)
        .reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, { message: 'Invalid code.' });

      await enterCode('123456');
      await submitCodeForm();
      await waitForPromises();

      expect(visitUrl).not.toHaveBeenCalled();
      expect(wrapper.text()).toContain('Invalid code.');
    });
  });

  describe('resending the code', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('posts to the resend path and shows a success alert', async () => {
      axiosMock.onPost(resendPath).reply(HTTP_STATUS_OK, { status: 'success' });

      await findResendButton().trigger('click');
      await waitForPromises();

      const resendRequest = axiosMock.history.post.find((req) => req.url === resendPath);
      expect(resendRequest).toBeDefined();
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({ variant: VARIANT_SUCCESS }),
      );
    });
  });

  describe('resend cooldown', () => {
    it('shows the resend link and no countdown when there is no active cooldown', async () => {
      // Default auto-send returns show_resend_after: null, which the component normalizes to 0.
      createComponent();
      await waitForPromises();

      expect(findResendButton().exists()).toBe(true);
      expect(findCountdown().exists()).toBe(false);
    });

    it('shows the countdown and hides the resend link while a cooldown is active', async () => {
      axiosMock.reset();
      const showResendAfter = Date.now() + 60000;
      axiosMock
        .onPost(sendEmailOtpPath)
        .reply(HTTP_STATUS_OK, { show_resend_after: showResendAfter });
      createComponent();
      await waitForPromises();

      expect(findCountdown().exists()).toBe(true);
      expect(findResendButton().exists()).toBe(false);
    });

    it('drops the stale countdown immediately when submitting another email', async () => {
      // Auto-send returns a future cooldown, so the countdown is showing on mount.
      axiosMock.reset();
      axiosMock
        .onPost(sendEmailOtpPath)
        .reply(HTTP_STATUS_OK, { show_resend_after: Date.now() + 60000 });
      axiosMock.onPost(resendPath).reply(HTTP_STATUS_OK, { status: 'success' });
      createComponent();
      await waitForPromises();

      expect(findCountdown().exists()).toBe(true);

      await findUseAnotherEmailButton().trigger('click');
      await findEmailForm().vm.$emit('submit-email', 'other@example.com');
      await nextTick();

      // Before the resend response resolves: no stale countdown, and the resend button shows
      // the in-flight (loading, disabled) state rather than an actionable "Resend code".
      expect(findCountdown().exists()).toBe(false);
      expect(findResendButton().props('loading')).toBe(true);
      expect(findResendButton().props('disabled')).toBe(true);

      await waitForPromises();
    });
  });

  describe('using another email', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('switches to the email form when "Use another email" is clicked', async () => {
      await findUseAnotherEmailButton().trigger('click');

      expect(findEmailForm().exists()).toBe(true);
      expect(findVerifyCodeForm().exists()).toBe(false);
    });

    it('resends to the entered address and returns to the code form', async () => {
      axiosMock.onPost(resendPath).reply(HTTP_STATUS_OK, { status: 'success' });

      await findUseAnotherEmailButton().trigger('click');
      await findEmailForm().vm.$emit('submit-email', 'other@example.com');
      await waitForPromises();

      const resendRequest = axiosMock.history.post.find((req) => req.url === resendPath);
      expect(JSON.parse(resendRequest.data)).toEqual({ user: { email: 'other@example.com' } });
      expect(findVerifyCodeForm().exists()).toBe(true);
      expect(wrapper.text()).toContain('other@example.com');
    });
  });
});
