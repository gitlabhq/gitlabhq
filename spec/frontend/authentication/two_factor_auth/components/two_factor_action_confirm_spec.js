import { GlFormGroup, GlModal } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoFactorActionConfirm from '~/authentication/two_factor_auth/components/two_factor_action_confirm.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const defaultProps = {
  buttonText: 'My button',
  message: 'my message',
  path: '/my/path',
  passwordRequired: true,
};

describe('TwoFactorActionConfirm', () => {
  let wrapper;

  const createComponent = (options = {}, mount = shallowMountExtended) => {
    wrapper = mount(TwoFactorActionConfirm, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...defaultProps,
        ...options,
      },
    });
  };

  const findButton = () => wrapper.findByTestId('2fa-action-button');
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');
  const findPasswordInput = () => wrapper.findComponent(PasswordInput);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('Initial button', () => {
    describe('when textual button', () => {
      it('renders text', () => {
        expect(findButton().text()).toBe(defaultProps.buttonText);
      });

      it('renders default `danger` variant', () => {
        expect(findButton().props('variant')).toBe('danger');
        expect(findButton().props('block')).toBe(true);
      });

      it('renders custom variant', () => {
        const variant = 'confirm';
        createComponent({ variant });

        expect(findButton().props('variant')).toBe(variant);
      });

      it('renders the modal when button is clicked', async () => {
        createComponent({}, mountExtended);
        expect(findModal().props('visible')).toBe(false);

        await findButton().trigger('click');

        expect(findModal().props('visible')).toBe(true);
      });
    });

    describe('when icon button', () => {
      const icon = 'remove';

      beforeEach(() => {
        createComponent({ icon });
      });

      it('renders icon with aria-label and title', () => {
        expect(findButton().props('icon')).toBe(icon);
        expect(findButton().attributes('aria-label')).toBe(defaultProps.buttonText);
        expect(findButton().attributes('title')).toBe(defaultProps.buttonText);
      });

      it('checks that tooltip is displayed', () => {
        const buttonTooltipDirective = getBinding(findButton().element, 'gl-tooltip');

        expect(buttonTooltipDirective).toBeDefined();
      });

      it('renders default `danger` variant', () => {
        expect(findButton().props('variant')).toBe('danger');
      });

      it('renders custom variant', () => {
        const variant = 'confirm';
        createComponent({ icon, variant });

        expect(findButton().props('variant')).toBe(variant);
      });

      it('renders the modal when button is clicked', async () => {
        createComponent({ icon }, mountExtended);
        expect(findModal().props('visible')).toBe(false);

        await findButton().trigger('click');

        expect(findModal().props('visible')).toBe(true);
      });
    });
  });

  describe('Modal', () => {
    it('renders with correct props', () => {
      const modal = findModal();
      expect(modal.props('title')).toBe(defaultProps.buttonText);
      expect(modal.props('size')).toBe('sm');
      expect(modal.text()).toBe(defaultProps.message);
      expect(findModal().props('actionCancel').text).toBe('Cancel');
    });

    it('renders a primary action button with default variant', () => {
      expect(findModal().props('actionPrimary').text).toBe(defaultProps.buttonText);
      expect(findModal().props('actionPrimary').attributes.variant).toBe('danger');
    });

    it('renders a primary action button with confirm variant', () => {
      createComponent({ variant: 'default' });

      expect(findModal().props('actionPrimary').attributes.variant).toBe('confirm');
    });
  });

  describe('Form', () => {
    it('contains correct attributes and inputs', () => {
      const form = findForm();
      expect(form.attributes('action')).toBe(defaultProps.path);
      expect(form.find('input[type=hidden][name=_method]').attributes('value')).toBe('delete');
      expect(form.find('input[type=hidden][name=authenticity_token]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('renders a custom hidden `_method` input', () => {
      const method = 'post';
      createComponent({ method });
      expect(findForm().find('input[type=hidden][name=_method]').attributes('value')).toBe(method);
    });
  });

  describe('when password is required', () => {
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

  describe('when password is not required', () => {
    beforeEach(() => {
      createComponent({ passwordRequired: false });
    });

    it('does not render password input field', () => {
      createComponent({ passwordRequired: false });

      expect(findPasswordInput().exists()).toBe(false);
    });

    it('submits the form without password', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');
      const preventDefault = jest.fn();
      findModal().vm.$emit('primary', { preventDefault });

      expect(preventDefault).toHaveBeenCalled();
      expect(submitSpy).toHaveBeenCalled();
    });
  });
});
