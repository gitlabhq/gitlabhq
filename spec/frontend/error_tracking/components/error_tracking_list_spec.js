import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import { GlButton, GlEmptyState, GlLoadingIcon, GlTable, GlLink } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorTrackingList', () => {
  let store;
  let wrapper;
  let actions;

  function mountComponent({
    errorTrackingEnabled = true,
    userCanEnableErrorTracking = true,
    stubs = {
      'gl-link': GlLink,
    },
  } = {}) {
    wrapper = shallowMount(ErrorTrackingList, {
      localVue,
      store,
      propsData: {
        indexPath: '/path',
        enableErrorTrackingLink: '/link',
        userCanEnableErrorTracking,
        errorTrackingEnabled,
        illustrationPath: 'illustration/path',
      },
      stubs,
    });
  }

  beforeEach(() => {
    actions = {
      getErrorList: () => {},
      startPolling: () => {},
      restartPolling: jest.fn().mockName('restartPolling'),
    };

    const state = {
      errors: [],
      loading: true,
    };

    store = new Vuex.Store({
      actions,
      state,
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows spinner', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
      expect(wrapper.find(GlTable).exists()).toBeFalsy();
      expect(wrapper.find(GlButton).exists()).toBeFalsy();
    });
  });

  describe('results', () => {
    beforeEach(() => {
      store.state.loading = false;

      mountComponent();
    });

    it('shows table', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeTruthy();
      expect(wrapper.find(GlButton).exists()).toBeTruthy();
    });
  });

  describe('no results', () => {
    beforeEach(() => {
      store.state.loading = false;

      mountComponent();
    });

    it('shows empty table', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeTruthy();
      expect(wrapper.find(GlButton).exists()).toBeTruthy();
    });

    it('shows a message prompting to refresh', () => {
      const refreshLink = wrapper.vm.$refs.empty.querySelector('a');

      expect(refreshLink.textContent.trim()).toContain('Check again');
    });

    it('restarts polling', () => {
      wrapper.find('.js-try-again').trigger('click');

      expect(actions.restartPolling).toHaveBeenCalled();
    });
  });

  describe('error tracking feature disabled', () => {
    beforeEach(() => {
      mountComponent({ errorTrackingEnabled: false });
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBeTruthy();
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeFalsy();
      expect(wrapper.find(GlButton).exists()).toBeFalsy();
    });
  });

  describe('When error tracking is disabled and user is not allowed to enable it', () => {
    beforeEach(() => {
      mountComponent({
        errorTrackingEnabled: false,
        userCanEnableErrorTracking: false,
        stubs: {
          'gl-link': GlLink,
          'gl-empty-state': GlEmptyState,
        },
      });
    });

    it('shows empty state', () => {
      expect(wrapper.find('a').attributes('href')).toBe(
        '/help/user/project/operations/error_tracking.html',
      );
    });
  });
});
