import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_DANGER } from '~/alert';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import ExtensionsMarketplaceWarning from '~/profile/preferences/components/extensions_marketplace_warning.vue';
import {
  i18n,
  INTEGRATION_EXTENSIONS_MARKETPLACE,
  INTEGRATION_VIEW_CONFIGS,
} from '~/profile/preferences/constants';
import {
  integrationViews,
  userFields,
  bodyClasses,
  colorModes,
  lightColorModeId,
  darkColorModeId,
  autoColorModeId,
  themes,
  themeId1,
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
    colorModes,
    themes,
    profilePreferencesPath: '/update-profile',
    formEl: document.createElement('form'),
  };
  const showToast = jest.fn();

  function createComponent(options = {}) {
    const { props = {}, provide = {}, attachTo } = options;
    return extendedWrapper(
      shallowMount(ProfilePreferences, {
        mocks: {
          $toast: {
            show: showToast,
          },
        },
        provide: {
          ...defaultProvide,
          ...provide,
        },
        propsData: props,
        attachTo,
        stubs: {
          SettingsSection,
        },
      }),
    );
  }

  function findIntegrationsHeading() {
    return wrapper.findByTestId('settings-section-heading');
  }

  function findSubmitButton() {
    return wrapper.findComponent(GlButton);
  }

  function createModeInput(modeId = lightColorModeId) {
    const input = document.createElement('input');
    input.setAttribute('name', 'user[color_mode_id]');
    input.setAttribute('type', 'radio');
    input.setAttribute('value', modeId.toString());
    input.setAttribute('checked', 'checked');
    return input;
  }

  function createThemeInput(themeId = themeId1) {
    const input = document.createElement('input');
    input.setAttribute('name', 'user[theme_id]');
    input.setAttribute('type', 'radio');
    input.setAttribute('value', themeId.toString());
    input.setAttribute('checked', 'checked');
    return input;
  }

  function createForm(inputs = [createModeInput(), createThemeInput()]) {
    const form = document.createElement('form');
    form.setAttribute('url', expectedUrl);
    form.setAttribute('method', 'put');
    inputs.forEach((input) => {
      form.appendChild(input);
    });
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
    const heading = findIntegrationsHeading();

    expect(heading.exists()).toBe(false);
    expect(views).toHaveLength(0);
  });

  it('should render Integration section', () => {
    wrapper = createComponent({ provide: { integrationViews } });
    const heading = findIntegrationsHeading();
    const views = wrapper.findAllComponents(IntegrationView);

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

      expect(showToast).toHaveBeenCalledWith(i18n.defaultSuccess);
    });

    it('displays the custom success message', () => {
      const message = 'foo';
      const successEvent = new CustomEvent('ajax:success', { detail: [{ message }] });
      form.dispatchEvent(successEvent);

      expect(showToast).toHaveBeenCalledWith(message);
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

  describe('color mode changes', () => {
    let colorModeInput;
    let themeInput;
    let form;

    function setupWrapper() {
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });
    }

    function selectColorModeId(modeId) {
      colorModeInput.setAttribute('value', modeId.toString());
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
      colorModeInput = createModeInput();
      themeInput = createThemeInput();
      form = createForm([colorModeInput, themeInput]);
    });

    it('reloads the page when switching from light to dark mode', async () => {
      selectColorModeId(lightColorModeId);
      setupWrapper();

      selectColorModeId(darkColorModeId);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('reloads the page when switching from dark to light mode', async () => {
      selectColorModeId(darkColorModeId);
      setupWrapper();

      selectColorModeId(lightColorModeId);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('reloads the page when switching from auto to light mode', async () => {
      selectColorModeId(autoColorModeId);
      setupWrapper();

      selectColorModeId(lightColorModeId);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });
  });

  describe('with extensions marketplace integration view', () => {
    beforeEach(() => {
      wrapper = createComponent({
        provide: {
          integrationViews: [
            {
              name: INTEGRATION_EXTENSIONS_MARKETPLACE,
              help_link: 'http://foo.com/help-extensions-marketplace',
              message: 'Click %{linkStart}Foo%{linkEnd}!',
              message_url: 'http://foo.com',
            },
          ],
        },
      });
    });

    it('renders view with 2-way-bound value', async () => {
      const integrationView = wrapper.findComponent(IntegrationView);

      expect(integrationView.props()).toMatchObject({
        value: false,
        config: INTEGRATION_VIEW_CONFIGS[INTEGRATION_EXTENSIONS_MARKETPLACE],
      });

      await integrationView.vm.$emit('input', true);

      expect(integrationView.props('value')).toBe(true);
    });

    it('renders extensions marketplace warning with 2-way-bound value', async () => {
      const warning = wrapper.findComponent(ExtensionsMarketplaceWarning);

      expect(warning.props()).toEqual({
        helpUrl: 'http://foo.com/help-extensions-marketplace',
        value: false,
      });

      await warning.vm.$emit('input', true);

      expect(warning.props('value')).toBe(true);
    });
  });
});
