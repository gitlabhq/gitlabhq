import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_DANGER } from '~/alert';
import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import { i18n } from '~/profile/preferences/constants';
import {
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
    bodyClasses,
    colorModes,
    themes,
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
      }),
    );
  }

  function findSubmitButton() {
    return wrapper.findComponent(GlButton);
  }

  function createRadioInput(name, value) {
    const input = document.createElement('input');
    input.setAttribute('name', name);
    input.setAttribute('type', 'radio');
    input.setAttribute('value', value.toString());
    input.setAttribute('checked', 'checked');
    return input;
  }

  function createModeInput(modeId = lightColorModeId) {
    return createRadioInput('user[color_mode_id]', modeId);
  }

  function createThemeInput(themeId = themeId1) {
    return createRadioInput('user[theme_id]', themeId);
  }

  function createLayoutInput(layout = 'fixed') {
    return createRadioInput('user[layout]', layout);
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

  afterEach(() => {
    document.body.innerHTML = '';
    document.body.className = '';
  });

  it('renders the sticky save button inside the settings footer', () => {
    wrapper = createComponent();

    expect(wrapper.classes()).toEqual(
      expect.arrayContaining(['settings-sticky-footer', 'js-hide-when-nothing-matches-search']),
    );
    expect(findSubmitButton().attributes('type')).toBe('submit');
    expect(findSubmitButton().text()).toBe(i18n.saveChanges);
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

  describe('layout changes', () => {
    const findContainer = () => document.querySelector('.content-wrapper .container-fluid');

    beforeEach(() => {
      setupBody();
    });

    it.each`
      layout     | limited
      ${'fluid'} | ${false}
      ${'fixed'} | ${true}
    `('applies the $layout layout without reloading on success', ({ layout, limited }) => {
      const form = createForm([createModeInput(), createThemeInput(), createLayoutInput(layout)]);
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });

      form.dispatchEvent(new CustomEvent('ajax:success'));

      expect(window.location.reload).not.toHaveBeenCalled();
      expect(findContainer().classList.contains('container-limited')).toBe(limited);
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
});
