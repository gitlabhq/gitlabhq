import { nextTick } from 'vue';
import { GlAlert, GlButton, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Registration from '~/authentication/webauthn/components/registration.vue';
import {
  I18N_BUTTON_REGISTER,
  I18N_BUTTON_SETUP,
  I18N_BUTTON_TRY_AGAIN,
  I18N_ERROR_HTTP,
  I18N_ERROR_UNSUPPORTED_BROWSER,
  I18N_STATUS_SUCCESS,
  I18N_STATUS_WAITING,
  STATE_ERROR,
  STATE_READY,
  STATE_SUCCESS,
  STATE_UNSUPPORTED,
  STATE_WAITING,
  WEBAUTHN_REGISTER,
} from '~/authentication/webauthn/constants';
import * as WebAuthnUtils from '~/authentication/webauthn/util';
import WebAuthnError from '~/authentication/webauthn/error';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));
jest.mock('~/authentication/webauthn/util');
jest.mock('~/authentication/webauthn/error');

describe('Registration', () => {
  const initialError = null;
  const passwordRequired = true;
  const targetPath = '/-/profile/two_factor_auth/create_webauthn';
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(Registration, {
      provide: { initialError, passwordRequired, targetPath, ...provide },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  describe(`when ${STATE_UNSUPPORTED} state`, () => {
    it('shows an error if using unsecure scheme (HTTP)', () => {
      // `supported` function returns false for HTTP because `navigator.credentials` is undefined.
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isHTTPS.mockReturnValue(false);
      createComponent();

      const alert = wrapper.findComponent(GlAlert);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toBe(I18N_ERROR_HTTP);
    });

    it('shows an error if using unsupported browser', () => {
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isHTTPS.mockReturnValue(true);
      createComponent();

      const alert = wrapper.findComponent(GlAlert);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toBe(I18N_ERROR_UNSUPPORTED_BROWSER);
    });
  });

  describe('when scheme or browser are supported', () => {
    const mockCreate = jest.fn();

    const clickSetupDeviceButton = () => {
      findButton().vm.$emit('click');
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

    describe(`when ${STATE_READY} state`, () => {
      it('shows button', () => {
        createComponent();

        expect(findButton().text()).toBe(I18N_BUTTON_SETUP);
      });
    });

    describe(`when ${STATE_WAITING} state`, () => {
      it('shows loading icon and message after pressing the button', async () => {
        createComponent();

        await clickSetupDeviceButton();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.text()).toContain(I18N_STATUS_WAITING);
      });
    });

    describe(`when ${STATE_SUCCESS} state`, () => {
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

          expect(wrapper.findComponent(GlForm).attributes('action')).toBe(targetPath);
        });

        describe('when password is required', () => {
          it('shows device name and password fields', async () => {
            createComponent();

            await setupDevice();

            expect(wrapper.text()).toContain(I18N_STATUS_SUCCESS);

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

            expect(findButton().text()).toBe(I18N_BUTTON_REGISTER);
          });

          it('enables the register device button when device name and password are filled', async () => {
            createComponent();

            await setupDevice();

            expect(findButton().props('disabled')).toBe(true);

            // Visible inputs
            findCurrentPasswordInput().vm.$emit('input', 'my current password');
            findDeviceNameInput().vm.$emit('input', 'my device name');
            await nextTick();

            expect(findButton().props('disabled')).toBe(false);
          });
        });

        describe('when password is not required', () => {
          it('shows a device name field', async () => {
            createComponent({ passwordRequired: false });

            await setupDevice();

            expect(wrapper.text()).toContain(I18N_STATUS_SUCCESS);

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

            expect(findButton().text()).toBe(I18N_BUTTON_REGISTER);
          });

          it('enables the register device button when device name is filled', async () => {
            createComponent({ passwordRequired: false });

            await setupDevice();

            expect(findButton().props('disabled')).toBe(true);

            findDeviceNameInput().vm.$emit('input', 'my device name');
            await nextTick();

            expect(findButton().props('disabled')).toBe(false);
          });
        });
      });
    });

    describe(`when ${STATE_ERROR} state`, () => {
      it('shows an initial error message and a retry button', () => {
        const myError = 'my error';
        createComponent({ initialError: myError });

        const alert = wrapper.findComponent(GlAlert);
        expect(alert.props()).toMatchObject({
          variant: 'danger',
          secondaryButtonText: I18N_BUTTON_TRY_AGAIN,
        });
        expect(alert.text()).toContain(myError);
      });

      it('shows an error message and a retry button', async () => {
        createComponent();
        const error = new Error();
        mockCreate.mockRejectedValueOnce(error);

        await setupDevice();

        expect(WebAuthnError).toHaveBeenCalledWith(error, WEBAUTHN_REGISTER);
        expect(wrapper.findComponent(GlAlert).props()).toMatchObject({
          variant: 'danger',
          secondaryButtonText: I18N_BUTTON_TRY_AGAIN,
        });
      });

      it('recovers after an error (error to success state)', async () => {
        createComponent();
        mockCreate.mockRejectedValueOnce(new Error()).mockResolvedValueOnce(true);

        await setupDevice();

        expect(wrapper.findComponent(GlAlert).props('variant')).toBe('danger');

        wrapper.findComponent(GlAlert).vm.$emit('secondaryAction');
        await waitForPromises();

        expect(wrapper.findComponent(GlAlert).props('variant')).toBe('info');
      });
    });
  });
});
