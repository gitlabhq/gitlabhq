import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlSearchBoxByClick,
} from '@gitlab/ui';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import errorsList from './list_mock.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorTrackingList', () => {
  let store;
  let wrapper;
  let actions;

  const findErrorListTable = () => wrapper.find('table');
  const findErrorListRows = () => wrapper.findAll('tbody tr');
  const findButton = () => wrapper.find(GlButton);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  function mountComponent({
    errorTrackingEnabled = true,
    userCanEnableErrorTracking = true,
    stubs = {
      'gl-link': GlLink,
      'gl-table': GlTable,
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
      errors: errorsList,
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
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findErrorListTable().exists()).toBe(false);
    });
  });

  describe('results', () => {
    beforeEach(() => {
      store.state.list.loading = false;
      mountComponent();
    });

    it('shows table', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorListTable().exists()).toBe(true);
      expect(findButton().exists()).toBe(true);
    });

    it('shows list of errors in a table', () => {
      expect(findErrorListRows().length).toEqual(store.state.list.errors.length);
    });

    it('each error in a list should have a link to the error page', () => {
      const errorTitle = wrapper.findAll('tbody tr a');

      errorTitle.wrappers.forEach((_, index) => {
        expect(errorTitle.at(index).attributes('href')).toEqual(
          expect.stringMatching(/error_tracking\/\d+\/details$/),
        );
      });
    });

    describe('filtering', () => {
      const findSearchBox = () => wrapper.find(GlSearchBoxByClick);

      it('shows search box', () => {
        expect(findSearchBox().exists()).toBe(true);
      });

      it('makes network request on submit', () => {
        expect(actions.startPolling).toHaveBeenCalledTimes(1);
        findSearchBox().vm.$emit('submit');
        expect(actions.startPolling).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('no results', () => {
    const findRefreshLink = () => wrapper.find('.js-try-again');

    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.errors = [];

      mountComponent();
    });

    it('shows empty table', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorListRows().length).toEqual(1);
      expect(findButton().exists()).toBe(true);
    });

    it('shows a message prompting to refresh', () => {
      expect(findRefreshLink().text()).toContain('Check again');
    });

    it('restarts polling', () => {
      findRefreshLink().trigger('click');
      expect(actions.restartPolling).toHaveBeenCalled();
    });
  });

  describe('error tracking feature disabled', () => {
    beforeEach(() => {
      mountComponent({ errorTrackingEnabled: false });
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorListTable().exists()).toBe(false);
      expect(findButton().exists()).toBe(false);
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
