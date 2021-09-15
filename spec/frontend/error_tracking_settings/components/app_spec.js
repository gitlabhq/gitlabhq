import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ErrorTrackingSettings from '~/error_tracking_settings/components/app.vue';
import ErrorTrackingForm from '~/error_tracking_settings/components/error_tracking_form.vue';
import ProjectDropdown from '~/error_tracking_settings/components/project_dropdown.vue';
import createStore from '~/error_tracking_settings/store';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('error tracking settings app', () => {
  let store;
  let wrapper;

  function mountComponent() {
    wrapper = extendedWrapper(
      shallowMount(ErrorTrackingSettings, {
        localVue,
        store, // Override the imported store
        propsData: {
          initialEnabled: 'true',
          initialIntegrated: 'false',
          initialApiHost: TEST_HOST,
          initialToken: 'someToken',
          initialProject: null,
          listProjectsEndpoint: TEST_HOST,
          operationsSettingsEndpoint: TEST_HOST,
        },
      }),
    );
  }

  const findBackendSettingsSection = () => wrapper.findByTestId('tracking-backend-settings');
  const findBackendSettingsRadioGroup = () =>
    findBackendSettingsSection().findComponent(GlFormRadioGroup);
  const findBackendSettingsRadioButtons = () =>
    findBackendSettingsRadioGroup().findAllComponents(GlFormRadio);
  const findElementWithText = (wrappers, text) => wrappers.filter((item) => item.text() === text);
  const findSentrySettings = () => wrapper.findByTestId('sentry-setting-form');

  beforeEach(() => {
    store = createStore();

    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('section', () => {
    it('renders the form and dropdown', () => {
      expect(wrapper.find(ErrorTrackingForm).exists()).toBeTruthy();
      expect(wrapper.find(ProjectDropdown).exists()).toBeTruthy();
    });

    it('renders the Save Changes button', () => {
      expect(wrapper.find('.js-error-tracking-button').exists()).toBeTruthy();
    });

    it('enables the button by default', () => {
      expect(wrapper.find('.js-error-tracking-button').attributes('disabled')).toBeFalsy();
    });

    it('disables the button when saving', () => {
      store.state.settingsLoading = true;

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.js-error-tracking-button').attributes('disabled')).toBeTruthy();
      });
    });
  });

  describe('tracking-backend settings', () => {
    it('contains a form-group with the correct label', () => {
      expect(findBackendSettingsSection().attributes('label')).toBe('Error tracking backend');
    });

    it('contains a radio group', () => {
      expect(findBackendSettingsRadioGroup().exists()).toBe(true);
    });

    it('contains the correct radio buttons', () => {
      expect(findBackendSettingsRadioButtons()).toHaveLength(2);

      expect(findElementWithText(findBackendSettingsRadioButtons(), 'Sentry')).toHaveLength(1);
      expect(findElementWithText(findBackendSettingsRadioButtons(), 'GitLab')).toHaveLength(1);
    });

    it('toggles the sentry-settings section when sentry is selected as a tracking-backend', async () => {
      expect(findSentrySettings().exists()).toBe(true);

      // set the "integrated" setting to "true"
      findBackendSettingsRadioGroup().vm.$emit('change', true);

      await nextTick();

      expect(findSentrySettings().exists()).toBe(false);
    });

    it.each([true, false])(
      'calls the `updateIntegrated` action when the setting changes to `%s`',
      (integrated) => {
        jest.spyOn(store, 'dispatch').mockImplementation();

        expect(store.dispatch).toHaveBeenCalledTimes(0);

        findBackendSettingsRadioGroup().vm.$emit('change', integrated);

        expect(store.dispatch).toHaveBeenCalledTimes(1);
        expect(store.dispatch).toHaveBeenCalledWith('updateIntegrated', integrated);
      },
    );
  });
});
