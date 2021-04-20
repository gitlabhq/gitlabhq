import { GlEmptyState, GlLoadingIcon, GlFormInput, GlPagination, GlDropdown } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';
import ErrorTrackingActions from '~/error_tracking/components/error_tracking_actions.vue';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import { trackErrorListViewsOptions, trackErrorStatusUpdateOptions } from '~/error_tracking/utils';
import Tracking from '~/tracking';
import errorsList from './list_mock.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorTrackingList', () => {
  let store;
  let wrapper;
  let actions;

  const findErrorListTable = () => wrapper.find('table');
  const findErrorListRows = () => wrapper.findAll('tbody tr');
  const dropdownsArray = () => wrapper.findAll(GlDropdown);
  const findRecentSearchesDropdown = () => dropdownsArray().at(0).find(GlDropdown);
  const findStatusFilterDropdown = () => dropdownsArray().at(1).find(GlDropdown);
  const findSortDropdown = () => dropdownsArray().at(2).find(GlDropdown);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findPagination = () => wrapper.find(GlPagination);
  const findErrorActions = () => wrapper.find(ErrorTrackingActions);

  function mountComponent({
    errorTrackingEnabled = true,
    userCanEnableErrorTracking = true,
    stubs = {},
  } = {}) {
    wrapper = mount(ErrorTrackingList, {
      localVue,
      store,
      propsData: {
        indexPath: '/path',
        listPath: '/error_tracking',
        projectPath: 'project/test',
        enableErrorTrackingLink: '/link',
        userCanEnableErrorTracking,
        errorTrackingEnabled,
        illustrationPath: 'illustration/path',
      },
      stubs: {
        ...stubChildren(ErrorTrackingList),
        ...stubs,
      },
    });
  }

  beforeEach(() => {
    actions = {
      startPolling: jest.fn(),
      restartPolling: jest.fn().mockName('restartPolling'),
      addRecentSearch: jest.fn(),
      loadRecentSearches: jest.fn(),
      setIndexPath: jest.fn(),
      clearRecentSearches: jest.fn(),
      setEndpoint: jest.fn(),
      searchByQuery: jest.fn(),
      sortByField: jest.fn(),
      fetchPaginatedResults: jest.fn(),
      updateStatus: jest.fn(),
      removeIgnoredResolvedErrors: jest.fn(),
      filterByStatus: jest.fn(),
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
      mountComponent({
        stubs: {
          GlTable: false,
          GlDropdown: false,
          GlDropdownItem: false,
          GlLink: false,
        },
      });
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

    it('each error in the list should have an action button set', () => {
      findErrorListRows().wrappers.forEach((row) => {
        expect(row.find(ErrorTrackingActions).exists()).toBe(true);
      });
    });

    describe('filtering', () => {
      const findSearchBox = () => wrapper.find(GlFormInput);

      it('shows search box & sort dropdown', () => {
        expect(findSearchBox().exists()).toBe(true);
        expect(findSortDropdown().exists()).toBe(true);
      });

      it('it searches by query', () => {
        findSearchBox().vm.$emit('input', 'search');
        findSearchBox().trigger('keyup.enter');
        expect(actions.searchByQuery.mock.calls[0][1]).toBe('search');
      });

      it('it sorts by fields', () => {
        const findSortItem = () => findSortDropdown().find('.dropdown-item');
        findSortItem().trigger('click');
        expect(actions.sortByField).toHaveBeenCalled();
      });

      it('it filters by status', () => {
        const findStatusFilter = () => findStatusFilterDropdown().find('.dropdown-item');
        findStatusFilter().trigger('click');
        expect(actions.filterByStatus).toHaveBeenCalled();
      });
    });
  });

  describe('no results', () => {
    const findRefreshLink = () => wrapper.find('.js-try-again');

    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.errors = [];

      mountComponent({
        stubs: {
          GlTable: false,
          GlDropdown: false,
          GlDropdownItem: false,
        },
      });
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
      findRefreshLink().vm.$emit('click');
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
      expect(dropdownsArray().length).toBe(0);
    });
  });

  describe('When the ignore button on an error is clicked', () => {
    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.errors = errorsList;

      mountComponent({
        stubs: {
          GlTable: false,
          GlLink: false,
        },
      });
    });

    it('sends the "ignored" status and error ID', () => {
      findErrorActions().vm.$emit('update-issue-status', {
        errorId: errorsList[0].id,
        status: 'ignored',
      });
      expect(actions.updateStatus).toHaveBeenCalledWith(expect.anything(), {
        endpoint: `/project/test/-/error_tracking/${errorsList[0].id}.json`,
        status: 'ignored',
      });
    });

    it('calls an action to remove the item from the list', () => {
      findErrorActions().vm.$emit('update-issue-status', { errorId: '1', status: undefined });
      expect(actions.removeIgnoredResolvedErrors).toHaveBeenCalledWith(expect.anything(), '1');
    });
  });

  describe('When the resolve button on an error is clicked', () => {
    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.errors = errorsList;

      mountComponent({
        stubs: {
          GlTable: false,
          GlLink: false,
        },
      });
    });

    it('sends "resolved" status and error ID', () => {
      findErrorActions().vm.$emit('update-issue-status', {
        errorId: errorsList[0].id,
        status: 'resolved',
      });
      expect(actions.updateStatus).toHaveBeenCalledWith(expect.anything(), {
        endpoint: `/project/test/-/error_tracking/${errorsList[0].id}.json`,
        status: 'resolved',
      });
    });

    it('calls an action to remove the item from the list', () => {
      findErrorActions().vm.$emit('update-issue-status', { errorId: '1', status: undefined });
      expect(actions.removeIgnoredResolvedErrors).toHaveBeenCalledWith(expect.anything(), '1');
    });
  });

  describe('When error tracking is disabled and user is not allowed to enable it', () => {
    beforeEach(() => {
      mountComponent({
        errorTrackingEnabled: false,
        userCanEnableErrorTracking: false,
        stubs: {
          GlLink: false,
          GlEmptyState: false,
        },
      });
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).isVisible()).toBe(true);
    });
  });

  describe('recent searches', () => {
    beforeEach(() => {
      mountComponent({
        stubs: {
          GlDropdown: false,
          GlDropdownItem: false,
        },
      });
    });

    it('shows empty message', () => {
      store.state.list.recentSearches = [];

      expect(findRecentSearchesDropdown().text()).toContain("You don't have any recent searches");
    });

    it('shows items', () => {
      store.state.list.recentSearches = ['great', 'search'];

      return wrapper.vm.$nextTick().then(() => {
        const dropdownItems = wrapper.findAll('.filtered-search-box li');
        expect(dropdownItems.length).toBe(3);
        expect(dropdownItems.at(0).text()).toBe('great');
        expect(dropdownItems.at(1).text()).toBe('search');
      });
    });

    describe('clear', () => {
      const clearRecentButton = () => wrapper.find({ ref: 'clearRecentSearches' });

      it('is hidden when list empty', () => {
        store.state.list.recentSearches = [];

        expect(clearRecentButton().exists()).toBe(false);
      });

      it('is visible when list has items', () => {
        store.state.list.recentSearches = ['some', 'searches'];

        return wrapper.vm.$nextTick().then(() => {
          expect(clearRecentButton().exists()).toBe(true);
          expect(clearRecentButton().text()).toBe('Clear recent searches');
        });
      });

      it('clears items on click', () => {
        store.state.list.recentSearches = ['some', 'searches'];

        return wrapper.vm.$nextTick().then(() => {
          clearRecentButton().vm.$emit('click');

          expect(actions.clearRecentSearches).toHaveBeenCalledTimes(1);
        });
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
        mountComponent({
          stubs: {
            GlPagination: false,
          },
        });
      });

      it('shows a disabled Prev button', () => {
        expect(wrapper.find('.prev-page-item').attributes('aria-disabled')).toBe('true');
      });
    });

    describe('and the user is not on the first page', () => {
      describe('and the previous button is clicked', () => {
        beforeEach(() => {
          store.state.list.loading = false;
          mountComponent({
            stubs: {
              GlTable: false,
              GlPagination: false,
            },
          });
          wrapper.setData({ pageValue: 2 });
          return wrapper.vm.$nextTick();
        });

        it('fetches the previous page of results', () => {
          expect(wrapper.find('.prev-page-item').attributes('aria-disabled')).toBe(undefined);
          wrapper.vm.goToPrevPage();
          expect(actions.fetchPaginatedResults).toHaveBeenCalled();
          expect(actions.fetchPaginatedResults).toHaveBeenLastCalledWith(
            expect.anything(),
            'previousCursor',
          );
        });
      });

      describe('and the next page button is clicked', () => {
        beforeEach(() => {
          store.state.list.loading = false;
          mountComponent();
        });

        it('fetches the next page of results', () => {
          window.scrollTo = jest.fn();
          findPagination().vm.$emit('input', 2);
          expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
          expect(actions.fetchPaginatedResults).toHaveBeenCalled();
          expect(actions.fetchPaginatedResults).toHaveBeenLastCalledWith(
            expect.anything(),
            'nextCursor',
          );
        });
      });
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      store.state.list.loading = false;
      store.state.list.errors = errorsList;
      mountComponent({
        stubs: {
          GlTable: false,
          GlLink: false,
        },
      });
    });

    it('should track list views', () => {
      const { category, action } = trackErrorListViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track status updates', () => {
      Tracking.event.mockClear();
      const status = 'ignored';
      findErrorActions().vm.$emit('update-issue-status', {
        errorId: 1,
        status,
      });

      setImmediate(() => {
        const { category, action } = trackErrorStatusUpdateOptions(status);
        expect(Tracking.event).toHaveBeenCalledWith(category, action);
      });
    });
  });
});
