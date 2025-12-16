import { GlModal } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmailOtpActionConfirm from '~/authentication/two_factor_auth/components/email_otp_action_confirm.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const buttonText = 'Save changes';
const buttonConfirmText = 'Update email OTP settings';

const defaultProps = {
  helpText: 'my help text',
  path: '/my/path',
  disabled: false,
  emailOtpRequired: false,
};

describe('EmailOtpActionConfirm', () => {
  let wrapper;

  const createComponent = (options = {}, mount = shallowMountExtended) => {
    wrapper = mount(EmailOtpActionConfirm, {
      directives: {},
      propsData: {
        ...defaultProps,
        ...options,
      },
    });
  };

  const findCheckbox = () => wrapper.findByTestId('email-otp-required-as-boolean');
  const findButton = () => wrapper.findByTestId('email-otp-action-button');
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');
  const findFormGroup = () => wrapper.findByTestId('email-otp-form-group');
  const findPasswordInput = () => wrapper.findComponent(PasswordInput);

  beforeEach(() => {
    createComponent();
  });

  describe('Initial button', () => {
    describe('for textual button', () => {
      it('renders text', () => {
        expect(findButton().text()).toBe(buttonText);
      });

      it('renders the modal when button is clicked', async () => {
        createComponent({}, mountExtended);

        expect(findModal().props('visible')).toBe(false);

        await findButton().trigger('click');

        expect(findModal().props('visible')).toBe(true);
      });
    });

    describe('for checkbox', () => {
      it('renders checkbox with correct props', () => {
        expect(findCheckbox().props('checked')).toBe(false);
      });
    });
  });

  describe('Modal', () => {
    it('renders with correct default props', () => {
      const modal = findModal();
      expect(modal.props('title')).toBe(buttonConfirmText);
      expect(modal.props('size')).toBe('sm');
      expect(modal.text()).toBe('Enter your password to continue.');
      expect(findModal().props('actionCancel').text).toBe('Cancel');
    });
  });

  describe('Form', () => {
    it('contains correct attributes and inputs', () => {
      const form = findForm();
      expect(form.attributes('action')).toBe(defaultProps.path);
      expect(form.attributes('method')).toBe('post');
      expect(form.find('input[type=hidden][name=_method]').attributes('value')).toBe('put');
      expect(form.find('input[type=hidden][name=authenticity_token]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('renders a password input field', () => {
      expect(findFormGroup().attributes('label')).toBe('Current password');
      expect(findPasswordInput().exists()).toBe(true);
    });

    it('does not submit the form without password', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');
      const preventDefault = jest.fn();
      findForm().element.current_password = { value: '' };
      findModal().vm.$emit('primary', { preventDefault });

      expect(preventDefault).toHaveBeenCalled();
      expect(submitSpy).not.toHaveBeenCalled();
    });

    it('submits the form with password', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');
      const preventDefault = jest.fn();
      findForm().element.current_password = { value: '123' };
      findModal().vm.$emit('primary', { preventDefault });

      expect(preventDefault).toHaveBeenCalled();
      expect(submitSpy).toHaveBeenCalled();
    });
  });
});
