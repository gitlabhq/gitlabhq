import { GlFormFields, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import htmlSessionsNew from 'test_fixtures/sessions/new_vue.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignInForm from '~/authentication/sign_in/components/sign_in_form.vue';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { useMockBoundingClientRect } from 'helpers/mock_bounding_client_rect';
import { visitUrl } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));
jest.mock('~/captcha/init_recaptcha_script', () => ({ initRecaptchaScript: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('SignInForm', () => {
  let wrapper;
  let defaultPropsData = {};

  // Mock requestAnimationFrame and boundingClientRect so the
  // autofocus functionality in `GlFormInput` works and we can
  // assert that the correct input is focused
  useFakeRequestAnimationFrame();
  useMockBoundingClientRect();

  beforeEach(() => {
    setHTMLFixture(htmlSessionsNew);
    const el = document.getElementById('js-sign-in-form');

    const railsFields = parseRailsFormFields(el);

    const {
      dataset: { appData },
    } = el;

    const {
      signInPath,
      usersSignInPathPath,
      passkeysSignInPath,
      signInPathIsScoped,
      isUnconfirmedEmail,
      newUserConfirmationPath,
      newPasswordPath,
      showCaptcha,
      isRememberMeEnabled,
    } = convertObjectPropsToCamelCase(JSON.parse(appData));

    resetHTMLFixture();

    defaultPropsData = {
      signInPath,
      usersSignInPathPath,
      passkeysSignInPath,
      signInPathIsScoped,
      isUnconfirmedEmail,
      newUserConfirmationPath,
      newPasswordPath,
      showCaptcha,
      isRememberMeEnabled,
      railsFields,
    };
  });

  afterEach(() => {
    defaultPropsData = {};
  });

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = mountExtended(SignInForm, {
      attachTo: document.body,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      provide,
    });
  };

  const findLoginField = () => wrapper.findByLabelText('Username or primary email');
  const findPasswordField = () => wrapper.findByLabelText('Password');
  const findPasswordInputComponent = () => wrapper.findComponent(PasswordInput);
  const findRememberMeCheckbox = () => wrapper.findByLabelText('Remember me');
  const findPasskeysForm = () => wrapper.findByTestId('passkey-form');
  const findSignInForm = () => wrapper.findByTestId('sign-in-form');
  const findSubmitButton = () => wrapper.findByTestId('sign-in-button');
  const fillInLoginAndContinue = async () => {
    await findLoginField().setValue('foo@bar.com');
    await findSubmitButton().trigger('click');
  };

  const expectLoginFieldToExist = () => {
    expect(findLoginField().attributes()).toMatchObject({
      id: defaultPropsData.railsFields.login.id,
      name: defaultPropsData.railsFields.login.name,
    });
  };
  const expectLoginFieldToBeFocused = async () => {
    await nextTick();
    expect(document.activeElement).toBe(findLoginField().element);
  };
  const expectPasswordFieldToExist = () => {
    expect(findPasswordField().attributes()).toMatchObject({
      id: defaultPropsData.railsFields.password.id,
      name: defaultPropsData.railsFields.password.name,
    });
    expect(findPasswordInputComponent().exists()).toBe(true);
  };
  const expectPasswordFieldToBeFocused = async () => {
    await nextTick();
    expect(document.activeElement).toBe(findPasswordField().element);
  };

  const submitForm = async () => {
    await wrapper.find('form').trigger('submit');
  };

  it('renders form with correct action and method', () => {
    createComponent();

    expect(findSignInForm().attributes()).toMatchObject({
      action: defaultPropsData.signInPath,
      method: 'post',
    });
  });

  describe('when URL has a fragment', () => {
    beforeEach(() => {
      setWindowLocation('https://gitlab.test/users/sign_in#foo');
      createComponent();
    });

    it('add fragment to form action', () => {
      expect(findSignInForm().attributes('action')).toBe(`${defaultPropsData.signInPath}#foo`);
    });
  });

  it('renders authenticity_token hidden input', () => {
    createComponent();

    expect(
      wrapper.find('input[type="hidden"][name="authenticity_token"]').attributes('value'),
    ).toBe(csrfToken);
  });

  it('renders login field with correct name and id attributes', async () => {
    createComponent();

    expectLoginFieldToExist();
    await expectLoginFieldToBeFocused();
  });

  it('validates login field', async () => {
    createComponent();
    await submitForm();

    expect(wrapper.text()).toContain('Username or primary email is required.');
  });

  describe('when login field has a value set (invite email)', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          railsFields: {
            ...defaultPropsData.railsFields,
            login: { ...defaultPropsData.railsFields.login, value: 'foo@bar.com' },
          },
        },
      });
    });

    it('prefills the login field', () => {
      expect(findLoginField().element.value).toBe('foo@bar.com');
    });
  });

  it('renders password field with correct name and id attributes', () => {
    createComponent();

    expectPasswordFieldToExist();
  });

  it('validates password field', async () => {
    createComponent();
    await submitForm();

    expect(wrapper.text()).toContain('Password is required.');
    expect(findPasswordInputComponent().props('state')).toBe(false);
  });

  it('renders remember me checkbox', () => {
    createComponent();

    expect(findRememberMeCheckbox().attributes()).toMatchObject({
      id: 'user_remember_me',
      autocomplete: 'off',
    });
  });

  it('renders hidden remember me input that is controlled by checkbox', async () => {
    createComponent();

    const hiddenRememberMeInput = wrapper.find(
      `input[type="hidden"][name="${defaultPropsData.railsFields.rememberMe.name}"]`,
    );

    expect(hiddenRememberMeInput.attributes('value')).toBe('0');

    await findRememberMeCheckbox().setChecked();

    expect(hiddenRememberMeInput.attributes('value')).toBe('1');
  });

  describe('when isRememberMeEnabled prop is false', () => {
    beforeEach(() => {
      createComponent({ propsData: { isRememberMeEnabled: false } });
    });

    it('does not render remember me checkbox', () => {
      expect(findRememberMeCheckbox().exists()).toBe(false);
    });
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

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('submits form', () => {
      createComponent();

      const submitMock = jest.fn();

      wrapper.findComponent(GlFormFields).vm.$emit('submit', { target: { submit: submitMock } });

      expect(submitMock).toHaveBeenCalled();
    });
  });

  describe('when passkeys feature flag is enabled', () => {
    beforeEach(() => {
      createComponent({ provide: { glFeatures: { passkeys: true } } });
    });

    it('renders form with passkeys button', () => {
      const form = findPasskeysForm();
      const submitButton = form.findComponent(GlButton);
      expect(form.attributes()).toMatchObject({
        method: 'post',
        action: defaultPropsData.passkeysSignInPath,
      });
      expect(form.find('input[type="hidden"][name="authenticity_token"]').attributes('value')).toBe(
        csrfToken,
      );
      expect(submitButton.attributes('type')).toBe('submit');
      expect(submitButton.props('icon')).toBe('passkey');
      expect(submitButton.text()).toBe('Passkey');
    });

    it('renders hidden remember me input that is controlled by remember me checkbox', async () => {
      const hiddenRememberMeInput = findPasskeysForm().find(
        'input[type="hidden"][name="remember_me"]',
      );

      expect(hiddenRememberMeInput.attributes('value')).toBe('0');

      await findRememberMeCheckbox().setChecked();

      expect(hiddenRememberMeInput.attributes('value')).toBe('1');
    });
  });

  describe('when twoStepSignIn feature flag is enabled', () => {
    const provide = { glFeatures: { passkeys: true, twoStepSignIn: true } };

    describe('when login field is not prefilled', () => {
      it('renders focused login field with correct name and id attributes', async () => {
        createComponent({ provide });

        expectLoginFieldToExist();
        await expectLoginFieldToBeFocused();
      });

      it('does not render password field', () => {
        createComponent({ provide });

        expect(findPasswordField().exists()).toBe(false);
      });

      it('renders submit button text as Continue', () => {
        createComponent({ provide });

        expect(findSubmitButton().text()).toBe('Continue');
      });

      it('does not render passkeys form', () => {
        createComponent({ provide });

        expect(findPasskeysForm().exists()).toBe(false);
      });

      describe('when user enters login and clicks Continue', () => {
        let mock;

        beforeEach(() => {
          mock = new MockAdapter(axios);
        });

        afterEach(() => {
          mock.restore();
        });

        describe('when API request is loading', () => {
          beforeEach(async () => {
            mock.onGet(defaultPropsData.usersSignInPathPath).reply(200, {
              sign_in_path: null,
            });
            createComponent({ provide });

            await fillInLoginAndContinue();
          });

          it('shows Continue button in loading state', async () => {
            expect(findSubmitButton().props('loading')).toBe(true);
            await waitForPromises();
            expect(findSubmitButton().props('loading')).toBe(false);
          });
        });

        describe('when API request is successful and returns { sign_in_path: null }', () => {
          beforeEach(async () => {
            mock.onGet(defaultPropsData.usersSignInPathPath).reply(200, {
              sign_in_path: null,
            });
            createComponent({ provide });

            await fillInLoginAndContinue();
            await waitForPromises();
          });

          it('shows and focuses password field', async () => {
            expectPasswordFieldToExist();
            await expectPasswordFieldToBeFocused();
          });
        });

        describe('when API request is successful and returns { sign_in_path: <sign in path> }', () => {
          const signInPath = '/users/sign_in?login=foo%40bar.com';

          beforeEach(() => {
            mock.onGet(defaultPropsData.usersSignInPathPath).reply(200, {
              sign_in_path: signInPath,
            });
          });

          it('redirects to sign in page', async () => {
            createComponent({ provide });

            await fillInLoginAndContinue();
            await waitForPromises();

            expect(visitUrl).toHaveBeenCalledWith(signInPath);
          });

          describe('when URL has a fragment', () => {
            beforeEach(async () => {
              setWindowLocation('https://gitlab.test/users/sign_in#foo');
              createComponent({ provide });

              await fillInLoginAndContinue();
              await waitForPromises();
            });

            it('redirects to sign in page with fragment', () => {
              expect(visitUrl).toHaveBeenCalledWith(`${signInPath}#foo`);
            });
          });

          describe('when remember me checkbox is checked', () => {
            it('adds remember_me=1 query param', async () => {
              createComponent({ provide });

              await findRememberMeCheckbox().setChecked();
              await fillInLoginAndContinue();
              await waitForPromises();

              expect(visitUrl).toHaveBeenCalledWith(`${signInPath}&remember_me=1`);
            });
          });
        });

        describe('when API is not successful', () => {
          beforeEach(() => {
            mock.onGet(defaultPropsData.usersSignInPathPath).networkError();
          });

          it('redirects to sign in page with login query param', async () => {
            createComponent({ provide });

            await fillInLoginAndContinue();
            await waitForPromises();

            expect(visitUrl).toHaveBeenCalledWith(
              `${defaultPropsData.signInPath}?login=foo%40bar.com`,
            );
          });

          describe('when URL has a fragment', () => {
            beforeEach(async () => {
              setWindowLocation('https://gitlab.test/users/sign_in#foo');
              createComponent({ provide });

              await fillInLoginAndContinue();
              await waitForPromises();
            });

            it('redirects to sign in page with login query param and fragment', () => {
              expect(visitUrl).toHaveBeenCalledWith(
                `${defaultPropsData.signInPath}?login=foo%40bar.com#foo`,
              );
            });
          });

          describe('when remember me checkbox is checked', () => {
            it('adds login and remember_me=1 query params', async () => {
              createComponent({ provide });

              await findRememberMeCheckbox().setChecked();
              await fillInLoginAndContinue();
              await waitForPromises();

              expect(visitUrl).toHaveBeenCalledWith(
                `${defaultPropsData.signInPath}?login=foo%40bar.com&remember_me=1`,
              );
            });
          });
        });
      });
    });

    describe('when login field is prefilled (from login query param)', () => {
      beforeEach(() => {
        createComponent({
          provide,
          propsData: {
            railsFields: {
              ...defaultPropsData.railsFields,
              login: { ...defaultPropsData.railsFields.login, value: 'foo@bar.com' },
            },
          },
        });
      });

      it('renders prefilled login field with correct name and id attributes', () => {
        expectLoginFieldToExist();
        expect(findLoginField().element.value).toBe('foo@bar.com');
      });

      it('renders focused password field with correct name and id attributes', async () => {
        expectPasswordFieldToExist();
        await expectPasswordFieldToBeFocused();
      });

      it('renders submit button text as Sign in', () => {
        expect(findSubmitButton().text()).toBe('Sign in');
      });
    });

    describe('when rememberMe field is prefilled (from remember_me query param)', () => {
      beforeEach(() => {
        createComponent({
          provide,
          propsData: {
            railsFields: {
              ...defaultPropsData.railsFields,
              rememberMe: { ...defaultPropsData.railsFields.rememberMe, value: '1' },
            },
          },
        });
      });

      it('renders remember me checkbox as checked', () => {
        expect(findRememberMeCheckbox().element.checked).toBe(true);
      });
    });
  });
});
