import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import {
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlSearchBoxByClick,
} from '@gitlab/ui';

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
      startPolling: jest.fn(),
      restartPolling: jest.fn().mockName('restartPolling'),
    };

    const state = {
      errors: [],
      loading: true,
    };

    store = new Vuex.Store({
      modules: {
        list: {
          namespaced: true,
          actions,
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
    beforeEach(() => {
      store.state.list.loading = true;
      mountComponent();
    });

    it('shows spinner', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
      expect(wrapper.find(GlTable).exists()).toBeFalsy();
    });
  });

  describe('results', () => {
    beforeEach(() => {
      store.state.list.loading = false;

      mountComponent();
    });

    it('shows table', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeTruthy();
      expect(wrapper.find(GlButton).exists()).toBeTruthy();
    });

    describe('filtering', () => {
      it('shows search box', () => {
        expect(wrapper.find(GlSearchBoxByClick).exists()).toBeTruthy();
      });

      it('makes network request on submit', () => {
        expect(actions.startPolling).toHaveBeenCalledTimes(1);

        wrapper.find(GlSearchBoxByClick).vm.$emit('submit');

        expect(actions.startPolling).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('no results', () => {
    beforeEach(() => {
      store.state.list.loading = false;

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
