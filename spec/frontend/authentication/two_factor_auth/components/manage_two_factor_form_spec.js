import { GlForm, GlModal } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
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
    wrapper = mountExtended(ManageTwoFactorForm, {
      provide: {
        ...defaultProvide,
        isCurrentPasswordRequired: options?.currentPasswordRequired ?? true,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <slot></slot>
              <slot name="modal-footer"></slot>
            </div>`,
        }),
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findMethodInput = () => wrapper.findByTestId('test-2fa-method-field');
  const findDisableButton = () => wrapper.findByTestId('test-2fa-disable-button');
  const findRegenerateCodesButton = () => wrapper.findByTestId('test-2fa-regenerate-codes-button');
  const findConfirmationModal = () => wrapper.findComponent(GlModal);

  const itShowsValidationMessageIfCurrentPasswordFieldIsEmpty = (findButtonFunction) => {
    it('shows validation message if `Current password` is empty', async () => {
      await findButtonFunction().trigger('click');

      expect(wrapper.findByText(i18n.currentPasswordInvalidFeedback).exists()).toBe(true);
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('`Current password` field', () => {
    describe('when required', () => {
      it('renders the current password field', () => {
        expect(wrapper.findByLabelText(i18n.currentPassword).exists()).toBe(true);
      });
    });

    describe('when not required', () => {
      beforeEach(() => {
        createComponent({
          currentPasswordRequired: false,
        });
      });

      it('does not render the current password field', () => {
        expect(wrapper.findByLabelText(i18n.currentPassword).exists()).toBe(false);
      });
    });
  });

  describe('Disable button', () => {
    it('renders the component with correct attributes', () => {
      expect(findDisableButton().exists()).toBe(true);
    });

    describe('when clicked', () => {
      itShowsValidationMessageIfCurrentPasswordFieldIsEmpty(findDisableButton);

      it('shows confirmation modal', async () => {
        await wrapper.findByLabelText('Current password').setValue('foo bar');
        await findDisableButton().trigger('click');

        expect(findConfirmationModal().props('visible')).toBe(true);
        expect(findConfirmationModal().html()).toContain(i18n.confirmWebAuthn);
      });

      it('modifies the form action and method when submitted through the button', async () => {
        const form = findForm();
        const methodInput = findMethodInput();
        const submitSpy = jest.spyOn(form.element, 'submit');

        await wrapper.findByLabelText('Current password').setValue('foo bar');
        await findDisableButton().trigger('click');

        expect(form.attributes('action')).toBe(defaultProvide.profileTwoFactorAuthPath);
        expect(methodInput.attributes('value')).toBe(defaultProvide.profileTwoFactorAuthMethod);

        findConfirmationModal().vm.$emit('primary');

        expect(submitSpy).toHaveBeenCalled();
      });
    });
  });

  describe('Regenerate recovery codes button', () => {
    it('renders the button', () => {
      expect(findRegenerateCodesButton().exists()).toBe(true);
    });

    describe('when clicked', () => {
      itShowsValidationMessageIfCurrentPasswordFieldIsEmpty(findRegenerateCodesButton);

      it('modifies the form action and method when submitted through the button', async () => {
        const form = findForm();
        const methodInput = findMethodInput();
        const submitSpy = jest.spyOn(form.element, 'submit');

        await wrapper.findByLabelText('Current password').setValue('foo bar');
        await findRegenerateCodesButton().trigger('click');

        expect(form.attributes('action')).toBe(defaultProvide.codesProfileTwoFactorAuthPath);
        expect(methodInput.attributes('value')).toBe(
          defaultProvide.codesProfileTwoFactorAuthMethod,
        );
        expect(submitSpy).toHaveBeenCalled();
      });
    });
  });
});
