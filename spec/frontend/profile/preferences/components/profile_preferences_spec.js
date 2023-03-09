import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_DANGER, VARIANT_INFO } from '~/alert';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import { i18n } from '~/profile/preferences/constants';
import {
  integrationViews,
  userFields,
  bodyClasses,
  themes,
  lightModeThemeId1,
  darkModeThemeId,
  lightModeThemeId2,
} from '../mock_data';

jest.mock('~/alert');
const expectedUrl = '/foo';

useMockLocationHelper();

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    integrationViews: [],
    userFields,
    bodyClasses,
    themes,
    profilePreferencesPath: '/update-profile',
    formEl: document.createElement('form'),
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {}, attachTo } = options;
    return extendedWrapper(
      shallowMount(ProfilePreferences, {
        provide: {
          ...defaultProvide,
          ...provide,
        },
        propsData: props,
        attachTo,
      }),
    );
  }

  function findIntegrationsDivider() {
    return wrapper.findByTestId('profile-preferences-integrations-rule');
  }

  function findIntegrationsHeading() {
    return wrapper.findByTestId('profile-preferences-integrations-heading');
  }

  function findSubmitButton() {
    return wrapper.findComponent(GlButton);
  }

  function createThemeInput(themeId = lightModeThemeId1) {
    const input = document.createElement('input');
    input.setAttribute('name', 'user[theme_id]');
    input.setAttribute('type', 'radio');
    input.setAttribute('value', themeId.toString());
    input.setAttribute('checked', 'checked');
    return input;
  }

  function createForm(themeInput = createThemeInput()) {
    const form = document.createElement('form');
    form.setAttribute('url', expectedUrl);
    form.setAttribute('method', 'put');
    form.appendChild(themeInput);
    return form;
  }

  function setupBody() {
    const div = document.createElement('div');
    div.classList.add('container-fluid');
    document.body.appendChild(div);
    document.body.classList.add('content-wrapper');
  }

  it('should not render Integrations section', () => {
    wrapper = createComponent();
    const views = wrapper.findAllComponents(IntegrationView);
    const divider = findIntegrationsDivider();
    const heading = findIntegrationsHeading();

    expect(divider.exists()).toBe(false);
    expect(heading.exists()).toBe(false);
    expect(views).toHaveLength(0);
  });

  it('should render Integration section', () => {
    wrapper = createComponent({ provide: { integrationViews } });
    const divider = findIntegrationsDivider();
    const heading = findIntegrationsHeading();
    const views = wrapper.findAllComponents(IntegrationView);

    expect(divider.exists()).toBe(true);
    expect(heading.exists()).toBe(true);
    expect(views).toHaveLength(integrationViews.length);
  });

  describe('form submit', () => {
    let form;

    beforeEach(() => {
      setupBody();
      form = createForm();
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });
      const beforeSendEvent = new CustomEvent('ajax:beforeSend');
      form.dispatchEvent(beforeSendEvent);
    });

    it('disables the submit button', async () => {
      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(true);
    });

    it('success re-enables the submit button', async () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('error re-enables the submit button', async () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('displays the default success message', () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.defaultSuccess,
        variant: VARIANT_INFO,
      });
    });

    it('displays the custom success message', () => {
      const message = 'foo';
      const successEvent = new CustomEvent('ajax:success', { detail: [{ message }] });
      form.dispatchEvent(successEvent);

      expect(createAlert).toHaveBeenCalledWith({ message, variant: VARIANT_INFO });
    });

    it('displays the default error message', () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.defaultError,
        variant: VARIANT_DANGER,
      });
    });

    it('displays the custom error message', () => {
      const message = 'bar';
      const errorEvent = new CustomEvent('ajax:error', { detail: [{ message }] });
      form.dispatchEvent(errorEvent);

      expect(createAlert).toHaveBeenCalledWith({ message, variant: VARIANT_DANGER });
    });
  });

  describe('theme changes', () => {
    let themeInput;
    let form;

    function setupWrapper() {
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });
    }

    function selectThemeId(themeId) {
      themeInput.setAttribute('value', themeId.toString());
    }

    function dispatchBeforeSendEvent() {
      const beforeSendEvent = new CustomEvent('ajax:beforeSend');
      form.dispatchEvent(beforeSendEvent);
    }

    function dispatchSuccessEvent() {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);
    }

    beforeEach(() => {
      setupBody();
      themeInput = createThemeInput();
      form = createForm(themeInput);
    });

    it('reloads the page when switching from light to dark mode', async () => {
      selectThemeId(lightModeThemeId1);
      setupWrapper();

      selectThemeId(darkModeThemeId);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('reloads the page when switching from dark to light mode', async () => {
      selectThemeId(darkModeThemeId);
      setupWrapper();

      selectThemeId(lightModeThemeId1);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('does not reload the page when switching between light mode themes', async () => {
      selectThemeId(lightModeThemeId1);
      setupWrapper();

      selectThemeId(lightModeThemeId2);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
