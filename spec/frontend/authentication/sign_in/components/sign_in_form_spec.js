import { GlFormFields } from '@gitlab/ui';
import { nextTick } from 'vue';
import htmlSessionsNew from 'test_fixtures/sessions/new_vue.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignInForm from '~/authentication/sign_in/components/sign_in_form.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));
jest.mock('~/captcha/init_recaptcha_script', () => ({ initRecaptchaScript: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');

describe('SignInForm', () => {
  let wrapper;
  let defaultPropsData = {};

  beforeEach(() => {
    setHTMLFixture(htmlSessionsNew);
    const el = document.getElementById('js-sign-in-form');

    const railsFields = parseRailsFormFields(el);

    const {
      dataset: { appData },
    } = el;

    const {
      signInPath,
      signInPathIsScoped,
      isUnconfirmedEmail,
      newUserConfirmationPath,
      newPasswordPath,
      showCaptcha,
    } = convertObjectPropsToCamelCase(JSON.parse(appData));

    resetHTMLFixture();

    defaultPropsData = {
      signInPath,
      signInPathIsScoped,
      isUnconfirmedEmail,
      newUserConfirmationPath,
      newPasswordPath,
      showCaptcha,
      railsFields,
    };
  });

  afterEach(() => {
    defaultPropsData = {};
  });

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(SignInForm, {
      attachTo: document.body,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findPasswordInputComponent = () => wrapper.findComponent(PasswordInput);

  const submitForm = async () => {
    await wrapper.find('form').trigger('submit');
  };

  it('renders authenticity_token hidden input', () => {
    createComponent();

    expect(
      wrapper.find('input[type="hidden"][name="authenticity_token"]').attributes('value'),
    ).toBe(csrfToken);
  });

  it('renders login field with correct name and id attributes', () => {
    createComponent();

    expect(wrapper.findByLabelText('Username or primary email').attributes()).toMatchObject({
      id: defaultPropsData.railsFields.login.id,
      name: defaultPropsData.railsFields.login.name,
    });
  });

  it('validates login field', async () => {
    createComponent();
    await submitForm();

    expect(wrapper.text()).toContain('Username or primary email is required.');
  });

  it('renders password field with correct name and id attributes', () => {
    createComponent();

    expect(wrapper.findByLabelText('Password').attributes()).toMatchObject({
      id: defaultPropsData.railsFields.password.id,
      name: defaultPropsData.railsFields.password.name,
    });
    expect(findPasswordInputComponent().exists()).toBe(true);
  });

  it('validates password field', async () => {
    createComponent();
    await submitForm();

    expect(wrapper.text()).toContain('Password is required.');
    expect(findPasswordInputComponent().props('state')).toBe(false);
  });

  it('renders hidden remember me input', () => {
    createComponent();

    expect(
      wrapper
        .find(`input[type="hidden"][name="${defaultPropsData.railsFields.rememberMe.name}"]`)
        .attributes('value'),
    ).toBe('0');
  });

  it('renders remember me checkbox with correct name attribute', () => {
    createComponent();

    expect(wrapper.findByLabelText('Remember me').attributes('name')).toBe(
      defaultPropsData.railsFields.rememberMe.name,
    );
  });

  describe('when isUnconfirmedEmail is false', () => {
    it('renders forgot password link', () => {
      createComponent();

      expect(wrapper.findByRole('link', { name: 'Forgot your password?' }).attributes('href')).toBe(
        defaultPropsData.newPasswordPath,
      );
    });
  });

  describe('when isUnconfirmedEmail is true', () => {
    it('renders link to resend confirmation email', () => {
      createComponent({ propsData: { isUnconfirmedEmail: true } });

      expect(
        wrapper.findByRole('link', { name: 'Resend confirmation email' }).attributes('href'),
      ).toBe(defaultPropsData.newUserConfirmationPath);
    });
  });

  describe('when showCaptcha is true', () => {
    it('renders captcha', async () => {
      const mockRecaptchaKey = 'mock-recaptcha-key';
      window.gon = {
        recaptcha_sitekey: mockRecaptchaKey,
      };

      const grecaptcha = {
        render: jest.fn(),
      };

      initRecaptchaScript.mockResolvedValueOnce(grecaptcha);

      createComponent({ propsData: { showCaptcha: true } });

      await waitForPromises();

      expect(grecaptcha.render).toHaveBeenCalledWith(wrapper.findByTestId('captcha-el').element, {
        sitekey: mockRecaptchaKey,
      });
    });

    describe('when captcha fails to render', () => {
      it('logs error to sentry', async () => {
        const error = new Error();

        initRecaptchaScript.mockRejectedValueOnce(error);

        createComponent({ propsData: { showCaptcha: true } });

        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('when GlFormFields emits submit event', () => {
    it('disables submit button', async () => {
      createComponent();

      const submitMock = jest.fn();

      wrapper.findComponent(GlFormFields).vm.$emit('submit', { target: { submit: submitMock } });
      await nextTick();

      expect(wrapper.findByTestId('sign-in-button').props('disabled')).toBe(true);
    });

    it('submits form', () => {
      createComponent();

      const submitMock = jest.fn();

      wrapper.findComponent(GlFormFields).vm.$emit('submit', { target: { submit: submitMock } });

      expect(submitMock).toHaveBeenCalled();
    });
  });
});
