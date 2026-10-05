import { nextTick } from 'vue';
import { GlAlert, GlButton, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import Registration from '~/authentication/webauthn/components/registration.vue';
import {
  I18N_BUTTON_REGISTER,
  I18N_BUTTON_SETUP,
  I18N_BUTTON_TRY_AGAIN,
  I18N_DEVICE_NAME_REQUIRED,
  I18N_ERROR_HTTP,
  I18N_ERROR_UNSUPPORTED_BROWSER,
  I18N_PASSWORD_REQUIRED,
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
jest.useFakeTimers();
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));
// Auto-mock util, but keep the pure requiredNonBlank validator real.
jest.mock('~/authentication/webauthn/util', () => ({
  ...jest.createMockFromModule('~/authentication/webauthn/util'),
  requiredNonBlank: jest.requireActual('~/authentication/webauthn/util').requiredNonBlank,
}));
jest.mock('~/authentication/webauthn/error');

describe('Registration', () => {
  const initialError = null;
  const passwordRequired = true;
  const targetPath = '/-/profile/two_factor_auth/create_webauthn';
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(Registration, {
      attachTo: document.body,
      provide: { initialError, passwordRequired, targetPath, ...provide },
      stubs: {
        GlAlert: stubComponent(GlAlert, {
          template: '<div><slot></slot><slot name="actions"></slot></div>',
        }),
      },
    });
  };

  const findPrimaryButton = () => wrapper.findComponent(GlButton);
  const findCancelButton = () => wrapper.findComponent('.js-toggle-button');
  const findForm = () => wrapper.findComponent(GlForm);

  describe(`when ${STATE_UNSUPPORTED} state`, () => {
    it('shows an error if using unsecure scheme (HTTP)', () => {
      // `supported` function returns false for HTTP because `navigator.credentials` is undefined.
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isSecureContext.mockReturnValue(false);
      createComponent();

      const alert = wrapper.findComponent(GlAlert);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toContain(I18N_ERROR_HTTP);
      expect(findCancelButton().exists()).toBe(true);
    });

    it('shows an error if using unsupported browser', () => {
      WebAuthnUtils.supported.mockReturnValue(false);
      WebAuthnUtils.isSecureContext.mockReturnValue(true);
      createComponent();

      const alert = wrapper.findComponent(GlAlert);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toContain(I18N_ERROR_UNSUPPORTED_BROWSER);
      expect(findCancelButton().exists()).toBe(true);
    });
  });

  describe('when scheme or browser are supported', () => {
    const mockCreate = jest.fn();

    const clickSetupDeviceButton = () => {
      findPrimaryButton().vm.$emit('click');
      return nextTick();
    };

    const setupDevice = () => {
      clickSetupDeviceButton();
      return waitForPromises();
    };

    beforeEach(() => {
      WebAuthnUtils.isSecureContext.mockReturnValue(true);
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

        expect(findPrimaryButton().text()).toBe(I18N_BUTTON_SETUP);
        expect(findCancelButton().text()).toBe('Cancel');
      });
    });

    describe(`when ${STATE_WAITING} state`, () => {
      it('shows loading icon and message after pressing the button', async () => {
        createComponent();

        await clickSetupDeviceButton();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.text()).toContain(I18N_STATUS_WAITING);
        expect(findCancelButton().exists()).toBe(true);
      });
    });

    describe(`when ${STATE_SUCCESS} state`, () => {
      const credentials = 1;

      const findCurrentPasswordInput = () => wrapper.findByTestId('current-password-input');
      const findDeviceNameInput = () => wrapper.findByTestId('device-name-input');
      const findSubmitButton = () => wrapper.find('button[type="submit"]');
      const submitForm = async () => {
        await wrapper.find('form').trigger('submit');
        await waitForPromises();
      };

      beforeEach(() => {
        mockCreate.mockResolvedValueOnce(true);
        WebAuthnUtils.convertCreateResponse.mockReturnValue(credentials);
      });

      describe('registration form', () => {
        it('has correct action', async () => {
          createComponent();

          await setupDevice();

          expect(findForm().attributes('action')).toBe(targetPath);
        });

        it('cancels the registration', async () => {
          createComponent();

          await setupDevice();
          expect(findForm().exists()).toBe(true);

          findCancelButton().vm.$emit('click');
          jest.advanceTimersByTime(1);
          await waitForPromises();

          expect(findForm().exists()).toBe(false);
          expect(findPrimaryButton().text()).toBe(I18N_BUTTON_SETUP);
          expect(findCancelButton().exists()).toBe(true);
        });

        describe('when password is required', () => {
          it('shows device name and password fields', async () => {
            createComponent();

            await setupDevice();

            expect(wrapper.text()).toContain(I18N_STATUS_SUCCESS);

            // Visible inputs
            expect(findCurrentPasswordInput().attributes('name')).toBe('current_password');
            expect(findDeviceNameInput().attributes('name')).toBe('device_registration[name]');
            expect(findCurrentPasswordInput().attributes('required')).toBeDefined();
            expect(findDeviceNameInput().attributes('required')).toBeDefined();

            // Hidden inputs
            expect(
              wrapper
                .find('input[name="device_registration[device_response]"]')
                .attributes('value'),
            ).toBe(`${credentials}`);
            expect(wrapper.find('input[name=authenticity_token]').attributes('value')).toBe(
              csrfToken,
            );

            expect(findSubmitButton().text()).toBe(I18N_BUTTON_REGISTER);
            expect(findCancelButton().exists()).toBe(true);
          });

          it('blocks submission and shows validation errors when the fields are empty', async () => {
            const submitSpy = jest
              .spyOn(HTMLFormElement.prototype, 'submit')
              .mockImplementation(() => {});
            createComponent();

            await setupDevice();
            await submitForm();

            expect(wrapper.text()).toContain(I18N_PASSWORD_REQUIRED);
            expect(wrapper.text()).toContain(I18N_DEVICE_NAME_REQUIRED);
            expect(submitSpy).not.toHaveBeenCalled();

            submitSpy.mockRestore();
          });

          it('submits the form when device name and password are filled', async () => {
            const submitSpy = jest
              .spyOn(HTMLFormElement.prototype, 'submit')
              .mockImplementation(() => {});
            createComponent();

            await setupDevice();

            await findCurrentPasswordInput().setValue('my current password');
            await findDeviceNameInput().setValue('my device name');
            await submitForm();

            expect(wrapper.text()).not.toContain(I18N_PASSWORD_REQUIRED);
            expect(wrapper.text()).not.toContain(I18N_DEVICE_NAME_REQUIRED);
            expect(submitSpy).toHaveBeenCalled();

            submitSpy.mockRestore();
          });

          it('blocks submission when the fields contain only whitespace', async () => {
            const submitSpy = jest
              .spyOn(HTMLFormElement.prototype, 'submit')
              .mockImplementation(() => {});
            createComponent();

            await setupDevice();

            await findCurrentPasswordInput().setValue('   ');
            await findDeviceNameInput().setValue('   ');
            await submitForm();

            expect(wrapper.text()).toContain(I18N_PASSWORD_REQUIRED);
            expect(wrapper.text()).toContain(I18N_DEVICE_NAME_REQUIRED);
            expect(submitSpy).not.toHaveBeenCalled();

            submitSpy.mockRestore();
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
            expect(findDeviceNameInput().attributes('required')).toBeDefined();

            // Hidden inputs
            expect(
              wrapper
                .find('input[name="device_registration[device_response]"]')
                .attributes('value'),
            ).toBe(`${credentials}`);
            expect(wrapper.find('input[name=authenticity_token]').attributes('value')).toBe(
              csrfToken,
            );

            expect(findSubmitButton().text()).toBe(I18N_BUTTON_REGISTER);
          });

          it('does not require a password to submit the form', async () => {
            const submitSpy = jest
              .spyOn(HTMLFormElement.prototype, 'submit')
              .mockImplementation(() => {});
            createComponent({ passwordRequired: false });

            await setupDevice();

            await findDeviceNameInput().setValue('my device name');
            await submitForm();

            expect(wrapper.text()).not.toContain(I18N_DEVICE_NAME_REQUIRED);
            expect(submitSpy).toHaveBeenCalled();

            submitSpy.mockRestore();
          });
        });
      });
    });

    describe(`when ${STATE_ERROR} state`, () => {
      it('shows an initial error message and a retry button', () => {
        const myError = 'my error';
        createComponent({ initialError: myError });

        const alert = wrapper.findComponent(GlAlert);
        expect(alert.text()).toContain(myError);
        const tryAgainButton = findPrimaryButton();
        expect(tryAgainButton.text()).toBe(I18N_BUTTON_TRY_AGAIN);
        expect(tryAgainButton.props('variant')).toBe('confirm');
      });

      it('shows an error message and a retry button', async () => {
        createComponent();
        const error = new Error();
        mockCreate.mockRejectedValueOnce(error);

        await setupDevice();

        expect(WebAuthnError).toHaveBeenCalledWith(error, WEBAUTHN_REGISTER);
        const tryAgainButton = findPrimaryButton();
        expect(tryAgainButton.text()).toBe(I18N_BUTTON_TRY_AGAIN);
        expect(tryAgainButton.props('variant')).toBe('confirm');
      });

      it('recovers after an error (error to success state)', async () => {
        createComponent();
        mockCreate.mockRejectedValueOnce(new Error()).mockResolvedValueOnce(true);

        await setupDevice();

        expect(wrapper.findComponent(GlAlert).props('variant')).toBe('danger');

        clickSetupDeviceButton();
        await waitForPromises();

        expect(wrapper.findComponent(GlAlert).props('variant')).toBe('info');
      });
    });
  });
});
