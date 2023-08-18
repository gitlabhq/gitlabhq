import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ErrorTrackingForm from '~/error_tracking_settings/components/error_tracking_form.vue';
import createStore from '~/error_tracking_settings/store';
import { defaultProps } from '../mock';

Vue.use(Vuex);

describe('error tracking settings form', () => {
  let wrapper;
  let store;

  function mountComponent() {
    wrapper = shallowMount(ErrorTrackingForm, {
      store,
      propsData: defaultProps,
    });
  }

  beforeEach(() => {
    store = createStore();
    mountComponent();
  });

  describe('an empty form', () => {
    it('is rendered', () => {
      expect(wrapper.findAllComponents(GlFormInput).length).toBe(2);
      expect(wrapper.findComponent(GlFormInput).attributes('id')).toBe('error-tracking-api-host');
      expect(wrapper.findAllComponents(GlFormInput).at(1).attributes('id')).toBe(
        'error-tracking-token',
      );
      expect(wrapper.findAllComponents(GlButton).exists()).toBe(true);
    });

    it('is rendered with labels and placeholders', () => {
      const pageText = wrapper.text();

      expect(pageText).toContain(
        "If you self-host Sentry, enter your Sentry instance's full URL. If you use Sentry's hosted solution, enter https://sentry.io",
      );
      expect(pageText).toContain(
        'After adding your Auth Token, select the Connect button to load projects.',
      );

      expect(pageText).not.toContain('Connection failed. Check Auth Token and try again.');
      expect(wrapper.findAllComponents(GlFormInput).at(0).attributes('placeholder')).toContain(
        'https://mysentryserver.com',
      );
    });
  });

  describe('loading projects', () => {
    beforeEach(() => {
      store.state.isLoadingProjects = true;
    });

    it('shows loading spinner', () => {
      const buttonEl = wrapper.findComponent(GlButton);

      expect(buttonEl.props('loading')).toBe(true);
      expect(buttonEl.text()).toBe('Connecting');
    });
  });

  describe('after a successful connection', () => {
    beforeEach(() => {
      store.state.connectSuccessful = true;
    });

    it('shows the success checkmark', () => {
      expect(wrapper.find('.js-error-tracking-connect-success').isVisible()).toBe(true);
    });

    it('does not show an error', () => {
      expect(wrapper.text()).not.toContain('Connection failed. Check Auth Token and try again.');
    });
  });

  describe('after an unsuccessful connection', () => {
    beforeEach(() => {
      store.state.connectError = true;
    });

    it('does not show the check mark', () => {
      expect(wrapper.find('.js-error-tracking-connect-success').isVisible()).toBe(false);
    });

    it('shows an error', () => {
      expect(wrapper.text()).toContain('Connection failed. Check Auth Token and try again.');
    });
  });
});
