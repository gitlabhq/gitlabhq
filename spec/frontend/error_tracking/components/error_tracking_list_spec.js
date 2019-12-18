import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  GlEmptyState,
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlPagination,
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
  const findSortDropdown = () => wrapper.find('.sort-dropdown');
  const findRecentSearchesDropdown = () =>
    wrapper.find('.filtered-search-history-dropdown-wrapper');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findPagination = () => wrapper.find(GlPagination);

  function mountComponent({
    errorTrackingEnabled = true,
    userCanEnableErrorTracking = true,
    sync = true,
    stubs = {
      'gl-link': GlLink,
      'gl-table': GlTable,
      'gl-pagination': GlPagination,
      'gl-dropdown': GlDropdown,
      'gl-dropdown-item': GlDropdownItem,
    },
  } = {}) {
    wrapper = shallowMount(ErrorTrackingList, {
      localVue,
      store,
      sync,
      propsData: {
        indexPath: '/path',
        enableErrorTrackingLink: '/link',
        userCanEnableErrorTracking,
        errorTrackingEnabled,
        illustrationPath: 'illustration/path',
      },
      stubs,
      data() {
        return { errorSearchQuery: 'search' };
      },
    });
  }

  beforeEach(() => {
    actions = {
      getErrorList: () => {},
      startPolling: jest.fn(),
      restartPolling: jest.fn().mockName('restartPolling'),
      addRecentSearch: jest.fn(),
      loadRecentSearches: jest.fn(),
      setIndexPath: jest.fn(),
      clearRecentSearches: jest.fn(),
      setEndpoint: jest.fn(),
      searchByQuery: jest.fn(),
      sortByField: jest.fn(),
    };

    const state = {
      indexPath: '',
      recentSearches: [],
      errors: errorsList,
      loading: true,
      pagination: {
        previous: {
          cursor: 'previousCursor',
        },
        next: {
          cursor: 'nextCursor',
        },
      },
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
      store.state.list.errors = errorsList;
      mountComponent();
    });

    it('shows table', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorListTable().exists()).toBe(true);
      expect(findSortDropdown().exists()).toBe(true);
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
      const findSearchBox = () => wrapper.find(GlFormInput);

      it('shows search box & sort dropdown', () => {
        expect(findSearchBox().exists()).toBe(true);
        expect(findSortDropdown().exists()).toBe(true);
      });

      it('it searches by query', () => {
        findSearchBox().trigger('keyup.enter');
        expect(actions.searchByQuery.mock.calls[0][1]).toEqual(wrapper.vm.errorSearchQuery);
      });

      it('it sorts by fields', () => {
        const findSortItem = () => wrapper.find('.dropdown-item');
        findSortItem().trigger('click');
        expect(actions.sortByField).toHaveBeenCalled();
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
      expect(findSortDropdown().exists()).toBe(true);
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
      expect(findSortDropdown().exists()).toBe(false);
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

  describe('recent searches', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows empty message', () => {
      store.state.list.recentSearches = [];

      expect(findRecentSearchesDropdown().text()).toContain("You don't have any recent searches");
    });

    it('shows items', () => {
      store.state.list.recentSearches = ['great', 'search'];

      const dropdownItems = wrapper.findAll('.filtered-search-box li');

      expect(dropdownItems.length).toBe(3);
      expect(dropdownItems.at(0).text()).toBe('great');
      expect(dropdownItems.at(1).text()).toBe('search');
    });

    describe('clear', () => {
      const clearRecentButton = () => wrapper.find({ ref: 'clearRecentSearches' });

      it('is hidden when list empty', () => {
        store.state.list.recentSearches = [];

        expect(clearRecentButton().exists()).toBe(false);
      });

      it('is visible when list has items', () => {
        store.state.list.recentSearches = ['some', 'searches'];

        expect(clearRecentButton().exists()).toBe(true);
        expect(clearRecentButton().text()).toBe('Clear recent searches');
      });

      it('clears items on click', () => {
        store.state.list.recentSearches = ['some', 'searches'];

        clearRecentButton().vm.$emit('click');

        expect(actions.clearRecentSearches).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('When pagination is not required', () => {
    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.pagination = {};
      mountComponent();
    });

    it('should not render the pagination component', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('When pagination is required', () => {
    describe('and the user is on the first page', () => {
      beforeEach(() => {
        store.state.list.loading = false;
        mountComponent({ sync: false });
      });

      it('shows a disabled Prev button', () => {
        expect(wrapper.find('.prev-page-item').attributes('aria-disabled')).toBe('true');
      });
    });

    describe('and the user is not on the first page', () => {
      describe('and the previous button is clicked', () => {
        beforeEach(() => {
          store.state.list.loading = false;
          mountComponent({ sync: false });
          wrapper.setData({ pageValue: 2 });
        });

        it('fetches the previous page of results', () => {
          expect(wrapper.find('.prev-page-item').attributes('aria-disabled')).toBe(undefined);
          wrapper.vm.goToPrevPage();
          expect(actions.startPolling).toHaveBeenCalledTimes(2);
          expect(actions.startPolling).toHaveBeenLastCalledWith(
            expect.anything(),
            '/path?cursor=previousCursor',
            undefined,
          );
        });
      });

      describe('and the next page button is clicked', () => {
        beforeEach(() => {
          store.state.list.loading = false;
          mountComponent({ sync: false });
        });

        it('fetches the next page of results', () => {
          window.scrollTo = jest.fn();
          findPagination().vm.$emit('input', 2);
          expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
          expect(actions.startPolling).toHaveBeenCalledTimes(2);
          expect(actions.startPolling).toHaveBeenLastCalledWith(
            expect.anything(),
            '/path?cursor=nextCursor',
            undefined,
          );
        });
      });
    });
  });
});
