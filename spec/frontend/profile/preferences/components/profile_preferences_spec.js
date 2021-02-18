import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import { i18n } from '~/profile/preferences/constants';
import { integrationViews, userFields, bodyClasses } from '../mock_data';

const expectedUrl = '/foo';

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    integrationViews: [],
    userFields,
    bodyClasses,
    themes: [{ id: 1, css_class: 'foo' }],
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

  function findFlashError() {
    return document.querySelector('.flash-container .flash-text');
  }

  beforeEach(() => {
    setFixtures('<div class="flash-container"></div>');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should not render Integrations section', () => {
    wrapper = createComponent();
    const views = wrapper.findAll(IntegrationView);
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
    const views = wrapper.findAll(IntegrationView);

    expect(divider.exists()).toBe(true);
    expect(heading.exists()).toBe(true);
    expect(views).toHaveLength(integrationViews.length);
  });

  describe('form submit', () => {
    let form;

    beforeEach(() => {
      const div = document.createElement('div');
      div.classList.add('container-fluid');
      document.body.appendChild(div);
      document.body.classList.add('content-wrapper');

      form = document.createElement('form');
      form.setAttribute('url', expectedUrl);
      form.setAttribute('method', 'put');

      const input = document.createElement('input');
      input.setAttribute('name', 'user[theme_id]');
      input.setAttribute('type', 'radio');
      input.setAttribute('value', '1');
      input.setAttribute('checked', 'checked');
      form.appendChild(input);

      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });

      const beforeSendEvent = new CustomEvent('ajax:beforeSend');
      form.dispatchEvent(beforeSendEvent);
    });

    it('disables the submit button', async () => {
      await wrapper.vm.$nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(true);
    });

    it('success re-enables the submit button', async () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      await wrapper.vm.$nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('error re-enables the submit button', async () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      await wrapper.vm.$nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('displays the default success message', () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      expect(findFlashError().innerText.trim()).toEqual(i18n.defaultSuccess);
    });

    it('displays the custom success message', () => {
      const message = 'foo';
      const successEvent = new CustomEvent('ajax:success', { detail: [{ message }] });
      form.dispatchEvent(successEvent);

      expect(findFlashError().innerText.trim()).toEqual(message);
    });

    it('displays the default error message', () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      expect(findFlashError().innerText.trim()).toEqual(i18n.defaultError);
    });

    it('displays the custom error message', () => {
      const message = 'bar';
      const errorEvent = new CustomEvent('ajax:error', { detail: [{ message }] });
      form.dispatchEvent(errorEvent);

      expect(findFlashError().innerText.trim()).toEqual(message);
    });
  });
});
