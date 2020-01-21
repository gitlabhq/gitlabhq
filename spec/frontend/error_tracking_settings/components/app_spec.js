import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
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
    wrapper = shallowMount(ErrorTrackingSettings, {
      localVue,
      store, // Override the imported store
      propsData: {
        initialEnabled: 'true',
        initialApiHost: TEST_HOST,
        initialToken: 'someToken',
        initialProject: null,
        listProjectsEndpoint: TEST_HOST,
        operationsSettingsEndpoint: TEST_HOST,
      },
    });
  }

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
});
