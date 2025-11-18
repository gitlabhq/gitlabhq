import { GlLink } from '@gitlab/ui';
import htmlWebauthnAuthenticate from 'test_fixtures/webauthn/authenticate.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import WebAuthnAuthenticate from '~/authentication/webauthn/components/authenticate.vue';
import EmailVerification from '~/sessions/new/components/email_verification.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import MockWebAuthnDevice from '../mock_webauthn_device';
import { useMockNavigatorCredentials } from '../util';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
jest.mock('~/lib/utils/axios_utils');

let wrapper;

const mockResponse = {
  type: 'public-key',
  id: '',
  rawId: '',
  response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
  getClientExtensionResults: () => {},
};

const createComponent = (propsData = {}) => {
  wrapper = mountExtended(WebAuthnAuthenticate, {
    propsData: {
      webauthnParams:
        // we need some valid base64 for base64ToBuffer
        // so we use "YQ==" = base64("a")
        {
          challenge: 'YQ==',
          timeout: 120000,
          allowCredentials: [
            { type: 'public-key', id: 'YQ==' },
            { type: 'public-key', id: 'YQ==' },
          ],
          userVerification: 'discouraged',
        },
      targetPath: '/webauthn',
      renderRememberMe: true,
      rememberMe: 'Remember me',
      sendEmailOtpPath: '',
      username: '',
      emailVerificationData: null,
      ...propsData,
    },
  });
};

describe('WebAuthnAuthenticate', () => {
  useMockNavigatorCredentials();

  let webAuthnDevice;
  let submitSpy;

  const findMessage = () => wrapper.find('#js-authenticate-token-2fa-error p');
  const findRetryButton = () => wrapper.find('#js-token-2fa-try-again');
  const findFallbackElement = () => document.querySelector('.js-2fa-form');
  const findInProgress = () => wrapper.find('p');
  const findAuthenticated = () => wrapper.find('#js-authenticate-token-2fa-authenticated p');
  const findFooter = () => wrapper.findByText(/Having trouble signing in\?/);
  const findRecoveryCodeLink = () => wrapper.findComponent(GlLink);
  const findEmailOtpButton = () => wrapper.findByTestId('send-email-otp-link');
  const findEmailVerification = () => wrapper.findComponent(EmailVerification);

  const expectAuthenticated = () => {
    expect(findAuthenticated().text()).toMatchInterpolatedText(
      'We heard back from your device. You have been authenticated.',
    );
    expect(wrapper.vm.deviceResponse).toBe(JSON.stringify(mockResponse));
    expect(submitSpy).toHaveBeenCalled();
  };

  beforeEach(() => {
    setHTMLFixture(htmlWebauthnAuthenticate);
    webAuthnDevice = new MockWebAuthnDevice();
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.clearAllMocks();
  });

  describe('with webauthn unavailable', () => {
    let oldGetCredentials;

    beforeEach(() => {
      oldGetCredentials = window.navigator.credentials.get;
      window.navigator.credentials.get = null;

      createComponent();
    });

    afterEach(() => {
      window.navigator.credentials.get = oldGetCredentials;
    });

    it('falls back to normal 2fa', () => {
      expect(wrapper.vm.fallbackMode).toBe(true);
      expect(findFallbackElement()).not.toHaveClass('hidden');
    });
  });

  describe('with webauthn available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows in progress', () => {
      const inProgressMessage = findInProgress();

      expect(inProgressMessage.text()).toMatchInterpolatedText(
        "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
      );
    });

    it('allows authenticating via a WebAuthn device', async () => {
      webAuthnDevice.respondToAuthenticateRequest(mockResponse);

      await waitForPromises();
      expectAuthenticated();
    });

    describe('errors', () => {
      beforeEach(() => {
        webAuthnDevice.rejectAuthenticateRequest(new DOMException());

        return waitForPromises();
      });

      it('displays an error message', () => {
        expect(submitSpy).not.toHaveBeenCalled();
        expect(findMessage().text()).toMatchInterpolatedText(
          'There was a problem communicating with your device. (Error)',
        );
      });

      it('allows retrying authentication after an error', async () => {
        findRetryButton().trigger('click');
        webAuthnDevice.respondToAuthenticateRequest(mockResponse);

        await waitForPromises();
        expectAuthenticated();
      });
    });
  });

  describe('email OTP fallback', () => {
    describe('when sendEmailOtpPath is not provided', () => {
      beforeEach(() => {
        createComponent({ sendEmailOtpPath: '' });
        webAuthnDevice.rejectAuthenticateRequest(new DOMException());

        return waitForPromises();
      });

      it('does not show the footer', () => {
        expect(findFooter().exists()).toBe(false);
      });
    });

    describe('when sendEmailOtpPath is provided', () => {
      beforeEach(() => {
        createComponent({
          sendEmailOtpPath: '/users/fallback_to_email_otp',
          username: 'testuser',
          emailVerificationData: {
            username: 'testuser',
            obfuscatedEmail: 't***@example.com',
            verifyPath: '/users/sign_in',
            resendPath: '/users/resend_verification_code',
            skipPath: null,
          },
        });
      });

      it('does not show footer when there is no error', () => {
        expect(findFooter().exists()).toBe(false);
      });

      describe('when authentication fails', () => {
        beforeEach(() => {
          webAuthnDevice.rejectAuthenticateRequest(new DOMException());

          return waitForPromises();
        });

        it('shows the footer with helpful links', () => {
          expect(findFooter().exists()).toBe(true);
          expect(wrapper.text()).toContain('Enter recovery code');
          expect(wrapper.text()).toContain('send code to email address');

          const link = findRecoveryCodeLink();
          expect(link.attributes('href')).toBe(
            '/help/user/profile/account/two_factor_authentication#recovery-codes',
          );
        });

        it('sends POST request when email OTP button is clicked', async () => {
          axios.post = jest.fn().mockResolvedValue({ data: { success: true } });

          await findEmailOtpButton().trigger('click');

          expect(axios.post).toHaveBeenCalledWith('/users/fallback_to_email_otp', {
            user: { login: 'testuser' },
          });
        });

        it('sets fallbackMode to true on success', async () => {
          axios.post = jest.fn().mockResolvedValue({ data: { success: true } });

          await findEmailOtpButton().trigger('click');
          await waitForPromises();

          expect(wrapper.vm.fallbackMode).toBe(true);
        });

        it('sets showEmailVerification to true on success', async () => {
          axios.post = jest.fn().mockResolvedValue({ data: { success: true } });

          await findEmailOtpButton().trigger('click');
          await waitForPromises();

          expect(wrapper.vm.showEmailVerification).toBe(true);
        });

        it('hides 2FA form on success', async () => {
          setHTMLFixture(`
            ${htmlWebauthnAuthenticate}
            <div class="js-2fa-form"></div>
          `);

          createComponent({
            sendEmailOtpPath: '/users/fallback_to_email_otp',
            username: 'testuser',
            emailVerificationData: {
              username: 'testuser',
              obfuscatedEmail: 't***@example.com',
              verifyPath: '/users/sign_in',
              resendPath: '/users/resend_verification_code',
              skipPath: null,
            },
          });

          webAuthnDevice.rejectAuthenticateRequest(new DOMException());
          await waitForPromises();

          const twoFaForm = document.querySelector('.js-2fa-form');
          axios.post = jest.fn().mockResolvedValue({ data: { success: true } });

          await findEmailOtpButton().trigger('click');
          await waitForPromises();

          expect(twoFaForm.classList.contains('hidden')).toBe(true);
        });

        it('shows EmailVerification component on success', async () => {
          axios.post = jest.fn().mockResolvedValue({ data: { success: true } });

          await findEmailOtpButton().trigger('click');
          await waitForPromises();

          expect(findEmailVerification().exists()).toBe(true);
          expect(findEmailVerification().props()).toMatchObject({
            username: 'testuser',
            obfuscatedEmail: 't***@example.com',
            verifyPath: '/users/sign_in',
            resendPath: '/users/resend_verification_code',
          });
        });

        it('shows error message in UI when email OTP request fails', async () => {
          axios.post = jest.fn().mockRejectedValue({
            response: { status: 422 },
          });

          await findEmailOtpButton().trigger('click');
          await waitForPromises();

          expect(wrapper.vm.fallbackMode).toBe(false);
          expect(findMessage().exists()).toBe(true);
          expect(findMessage().text()).toContain(
            'Failed to send email OTP. Please try again. If the problem persists, refresh your page or sign in again.',
          );
        });
      });
    });
  });

  describe('switchToFallbackUI', () => {
    beforeEach(() => {
      createComponent();
    });

    it('removes hidden class from 2FA form if it exists, sets fallbackMode to true', () => {
      const form = findFallbackElement();
      form.classList.add('hidden');

      wrapper.vm.switchToFallbackUI();

      expect(wrapper.vm.fallbackMode).toBe(true);
      expect(form.classList.contains('hidden')).toBe(false);
    });
  });

  describe('AbortController', () => {
    beforeEach(() => {
      createComponent({
        sendEmailOtpPath: '/users/fallback_to_email_otp',
        username: 'testuser',
        emailVerificationData: {
          username: 'testuser',
          obfuscatedEmail: 't***@example.com',
          verifyPath: '/users/sign_in',
          resendPath: '/users/resend_verification_code',
          skipPath: null,
        },
      });
    });
  });
});
