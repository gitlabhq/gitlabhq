import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import SentryErrorStackTrace from '~/sentry_error_stack_trace/components/sentry_error_stack_trace.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Sentry Error Stack Trace', () => {
  let actions;
  let getters;
  let store;
  let wrapper;

  function mountComponent({
    stubs = {
      stacktrace: Stacktrace,
    },
  } = {}) {
    wrapper = shallowMount(SentryErrorStackTrace, {
      localVue,
      stubs,
      store,
      propsData: {
        issueStackTracePath: '/stacktrace',
      },
    });
  }

  beforeEach(() => {
    actions = {
      startPollingStacktrace: () => {},
    };

    getters = {
      stacktrace: () => [{ context: [1, 2], lineNo: 53, filename: 'index.js' }],
    };

    const state = {
      stacktraceData: {},
      loadingStacktrace: true,
    };

    store = new Vuex.Store({
      modules: {
        details: {
          namespaced: true,
          actions,
          getters,
          state,
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('loading', () => {
    it('should show spinner while loading', () => {
      mountComponent();
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
    });
  });

  describe('Stack trace', () => {
    it('should show stacktrace', () => {
      store.state.details.loadingStacktrace = false;
      mountComponent({ stubs: {} });
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(Stacktrace).exists()).toBe(true);
    });

    it('should not show stacktrace if it does not exist', () => {
      store.state.details.loadingStacktrace = false;
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
    });
  });
});
