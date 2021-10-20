import { within } from '@testing-library/dom';
import { GlForm } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ManageTwoFactorForm, {
  i18n,
} from '~/authentication/two_factor_auth/components/manage_two_factor_form.vue';

const defaultProvide = {
  profileTwoFactorAuthPath: '2fa_auth_path',
  profileTwoFactorAuthMethod: '2fa_auth_method',
  codesProfileTwoFactorAuthPath: '2fa_codes_path',
  codesProfileTwoFactorAuthMethod: '2fa_codes_method',
};

describe('ManageTwoFactorForm', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      mount(ManageTwoFactorForm, {
        provide: {
          ...defaultProvide,
          webauthnEnabled: options?.webauthnEnabled ?? false,
          isCurrentPasswordRequired: options?.currentPasswordRequired ?? true,
        },
      }),
    );
  };

  const queryByText = (text, options) => within(wrapper.element).queryByText(text, options);
  const queryByLabelText = (text, options) =>
    within(wrapper.element).queryByLabelText(text, options);

  const findForm = () => wrapper.findComponent(GlForm);
  const findMethodInput = () => wrapper.findByTestId('test-2fa-method-field');
  const findDisableButton = () => wrapper.findByTestId('test-2fa-disable-button');
  const findRegenerateCodesButton = () => wrapper.findByTestId('test-2fa-regenerate-codes-button');

  beforeEach(() => {
    createComponent();
  });

  describe('Current password field', () => {
    it('renders the current password field', () => {
      expect(queryByLabelText(i18n.currentPassword).tagName).toEqual('INPUT');
    });
  });

  describe('when current password is not required', () => {
    beforeEach(() => {
      createComponent({
        currentPasswordRequired: false,
      });
    });

    it('does not render the current password field', () => {
      expect(queryByLabelText(i18n.currentPassword)).toBe(null);
    });
  });

  describe('Disable button', () => {
    it('renders the component with correct attributes', () => {
      expect(findDisableButton().exists()).toBe(true);
      expect(findDisableButton().attributes()).toMatchObject({
        'data-confirm': i18n.confirm,
        'data-form-action': defaultProvide.profileTwoFactorAuthPath,
        'data-form-method': defaultProvide.profileTwoFactorAuthMethod,
      });
    });

    it('has the right confirm text', () => {
      expect(findDisableButton().attributes('data-confirm')).toBe(i18n.confirm);
    });

    describe('when webauthnEnabled', () => {
      beforeEach(() => {
        createComponent({
          webauthnEnabled: true,
        });
      });

      it('has the right confirm text', () => {
        expect(findDisableButton().attributes('data-confirm')).toBe(i18n.confirmWebAuthn);
      });
    });

    it('modifies the form action and method when submitted through the button', async () => {
      const form = findForm();
      const disableButton = findDisableButton().element;
      const methodInput = findMethodInput();

      await form.vm.$emit('submit', { submitter: disableButton });

      expect(form.attributes('action')).toBe(defaultProvide.profileTwoFactorAuthPath);
      expect(methodInput.attributes('value')).toBe(defaultProvide.profileTwoFactorAuthMethod);
    });
  });

  describe('Regenerate recovery codes button', () => {
    it('renders the button', () => {
      expect(queryByText(i18n.regenerateRecoveryCodes)).toEqual(expect.any(HTMLElement));
    });

    it('modifies the form action and method when submitted through the button', async () => {
      const form = findForm();
      const regenerateCodesButton = findRegenerateCodesButton().element;
      const methodInput = findMethodInput();

      await form.vm.$emit('submit', { submitter: regenerateCodesButton });

      expect(form.attributes('action')).toBe(defaultProvide.codesProfileTwoFactorAuthPath);
      expect(methodInput.attributes('value')).toBe(defaultProvide.codesProfileTwoFactorAuthMethod);
    });
  });
});
