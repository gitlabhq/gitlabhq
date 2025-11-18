import { nextTick } from 'vue';
import { GlAlert, GlButton, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import Registration from '~/authentication/webauthn/components/passkey_registration.vue';
import { WEBAUTHN_REGISTER } from '~/authentication/webauthn/constants';
import * as WebAuthnUtils from '~/authentication/webauthn/util';
import WebAuthnError from '~/authentication/webauthn/error';
import { createAlert } from '~/alert';

const csrfToken = 'mock-csrf-token';
jest.useFakeTimers();
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));
jest.mock('~/authentication/webauthn/util');
jest.mock('~/authentication/webauthn/error');
jest.mock('~/alert');

describe('Registration', () => {
  const initialError = null;
  const passwordRequired = true;
  const path = '/-/profile/two_factor_auth/create_webauthn';
  const twoFactorAuthPath = '/-/profile/two_factor_auth';
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(Registration, {
      provide: { initialError, passwordRequired, path, twoFactorAuthPath, ...provide },
      stubs: {
        GlAlert: stubComponent(GlAlert, {
          template: '<div><slot></slot><slot name="actions"></slot></div>',
        }),
      },
    });
  };

  const findPrimaryButton = () => wrapper.findComponent(GlButton);
  const findCancelButton = () => wrapper.findByTestId('cancel-btn');
  const findForm = () => wrapper.findComponent(GlForm);

  describe(`when unsupported 'error' state`, () => {
    it('shows an error if using unsecure scheme (HTTP)', () => {
      // `supported` function returns false for HTTP because `navigator.credentials` is undefined.
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isHTTPS.mockReturnValue(false);
      createComponent();

      expect(createAlert).toHaveBeenCalledWith({
        message:
          'Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
        variant: 'danger',
      });

      expect(findCancelButton().exists()).toBe(true);
    });

    it('shows an error if using unsupported browser', () => {
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isHTTPS.mockReturnValue(true);
      createComponent();

      expect(createAlert).toHaveBeenCalledWith({
        message: "Your browser doesn't support passkeys.",
        variant: 'danger',
      });

      expect(findCancelButton().exists()).toBe(true);
    });
  });

  describe('when scheme or browser are supported', () => {
    const mockCreate = jest.fn();

    const clickSetupDeviceButton = () => {
      findPrimaryButton().vm.$emit('click');
      return nextTick();
    };

    const clickCancelButton = () => {
      findCancelButton().vm.$emit('click');
      return nextTick();
    };

    const setupDevice = () => {
      clickSetupDeviceButton();
      return waitForPromises();
    };

    beforeEach(() => {
      WebAuthnUtils.isHTTPS.mockReturnValue(true);
      WebAuthnUtils.supported.mockReturnValue(true);
      global.navigator.credentials = { create: mockCreate };
      gon.webauthn = { options: {} };
    });

    afterEach(() => {
      global.navigator.credentials = undefined;
    });

    describe(`when 'ready' state`, () => {
      it('shows button', async () => {
        const myError = 'my error';
        createComponent({ initialError: myError });

        clickCancelButton();
        await nextTick();

        expect(findPrimaryButton().text()).toBe('Try again');
        expect(findCancelButton().text()).toBe('Cancel');
      });
    });

    describe(`when 'waiting' state`, () => {
      it('shows loading icon and message on page load', () => {
        createComponent();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.text()).toContain('Try again');
        expect(findCancelButton().exists()).toBe(true);
      });
    });

    describe(`when 'success' state`, () => {
      const credentials = 1;

      const findCurrentPasswordInput = () => wrapper.findByTestId('current-password-input');
      const findDeviceNameInput = () => wrapper.findByTestId('device-name-input');

      beforeEach(() => {
        mockCreate.mockResolvedValueOnce(true);
        WebAuthnUtils.convertCreateResponse.mockReturnValue(credentials);
      });

      describe('registration form', () => {
        it('has correct action', async () => {
          createComponent();

          await setupDevice();

          expect(findForm().attributes('action')).toBe(path);
        });

        it('cancels the registration', async () => {
          createComponent();

          await setupDevice();

          expect(findCancelButton().exists()).toBe(true);
          expect(findCancelButton().attributes().href).toEqual(twoFactorAuthPath);
        });

        describe('when password is required', () => {
          it('shows device name and password fields', async () => {
            createComponent();

            await setupDevice();

            // Visible inputs
            expect(findCurrentPasswordInput().attributes('name')).toBe('current_password');
            expect(findDeviceNameInput().attributes('name')).toBe('device_registration[name]');

            // Hidden inputs
            expect(
              wrapper
                .find('input[name="device_registration[device_response]"]')
                .attributes('value'),
            ).toBe(`${credentials}`);
            expect(wrapper.find('input[name=authenticity_token]').attributes('value')).toBe(
              csrfToken,
            );

            expect(findPrimaryButton().text()).toBe('Add passkey');
            expect(findCancelButton().exists()).toBe(true);
          });
        });

        describe('when password is not required', () => {
          it('shows a device name field', async () => {
            createComponent({ passwordRequired: false });

            await setupDevice();

            // Visible inputs
            expect(findCurrentPasswordInput().exists()).toBe(false);
            expect(findDeviceNameInput().attributes('name')).toBe('device_registration[name]');

            // Hidden inputs
            expect(
              wrapper
                .find('input[name="device_registration[device_response]"]')
                .attributes('value'),
            ).toBe(`${credentials}`);
            expect(wrapper.find('input[name=authenticity_token]').attributes('value')).toBe(
              csrfToken,
            );

            expect(findPrimaryButton().text()).toBe('Add passkey');
          });
        });
      });
    });

    describe(`when 'error' state`, () => {
      it('shows an initial error message and a retry button', () => {
        const myError = 'my error';
        createComponent({ initialError: myError });

        expect(createAlert).toHaveBeenCalledWith({
          message: myError,
          variant: 'danger',
        });

        const tryAgainButton = findPrimaryButton();
        expect(tryAgainButton.text()).toBe('Try again');
        expect(tryAgainButton.props('variant')).toBe('confirm');
      });

      it('shows an error message and a retry button', async () => {
        const error = new Error();
        mockCreate.mockRejectedValueOnce(error);

        createComponent();

        await waitForPromises();

        expect(WebAuthnError).toHaveBeenCalledWith(error, WEBAUTHN_REGISTER);
        const tryAgainButton = findPrimaryButton();
        expect(tryAgainButton.text()).toBe('Try again');
        expect(tryAgainButton.props('variant')).toBe('confirm');
      });

      it('recovers after an error (error to ready state)', async () => {
        mockCreate.mockRejectedValueOnce(new Error()).mockResolvedValueOnce(true);
        createComponent();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: undefined,
          variant: 'danger',
        });

        clickSetupDeviceButton();
        await waitForPromises();

        expect(findForm().exists()).toBe(true);
      });
    });
  });
});
