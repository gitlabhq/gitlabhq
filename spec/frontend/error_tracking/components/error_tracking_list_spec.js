import { GlEmptyState, GlLoadingIcon, GlFormInput, GlPagination, GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';
import ErrorTrackingActions from '~/error_tracking/components/error_tracking_actions.vue';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import {
  trackErrorListViewsOptions,
  trackErrorStatusUpdateOptions,
  trackErrorStatusFilterOptions,
  trackErrorSortedByField,
} from '~/error_tracking/events_tracking';
import Tracking from '~/tracking';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import errorsList from './list_mock.json';

Vue.use(Vuex);

describe('ErrorTrackingList', () => {
  let store;
  let wrapper;
  let actions;

  const findErrorListTable = () => wrapper.find('table');
  const findErrorListRows = () => wrapper.findAll('tbody tr');
  const dropdownsArray = () => wrapper.findAllComponents(GlDropdown);
  const findRecentSearchesDropdown = () => dropdownsArray().at(0).findComponent(GlDropdown);
  const findStatusFilterDropdown = () => dropdownsArray().at(1).findComponent(GlDropdown);
  const findSortDropdown = () => dropdownsArray().at(2).findComponent(GlDropdown);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findErrorActions = () => wrapper.findComponent(ErrorTrackingActions);
  const findIntegratedDisabledAlert = () => wrapper.findByTestId('integrated-disabled-alert');

  function mountComponent({
    errorTrackingEnabled = true,
    userCanEnableErrorTracking = true,
    showIntegratedTrackingDisabledAlert = false,
    stubs = {},
  } = {}) {
    wrapper = extendedWrapper(
      mount(ErrorTrackingList, {
        store,
        propsData: {
          indexPath: '/path',
          listPath: '/error_tracking',
          projectPath: 'project/test',
          enableErrorTrackingLink: '/link',
          userCanEnableErrorTracking,
          errorTrackingEnabled,
          showIntegratedTrackingDisabledAlert,
          illustrationPath: 'illustration/path',
        },
        stubs: {
          ...stubChildren(ErrorTrackingList),
          ...stubs,
        },
      }),
    );
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
        expect(row.findComponent(ErrorTrackingActions).exists()).toBe(true);
      });
    });

    describe('filtering', () => {
      const findSearchBox = () => wrapper.findComponent(GlFormInput);

      it('shows search box & sort dropdown', () => {
        expect(findSearchBox().exists()).toBe(true);
        expect(findSortDropdown().exists()).toBe(true);
      });

      it('searches by query', () => {
        findSearchBox().vm.$emit('input', 'search');
        findSearchBox().trigger('keyup.enter');
        expect(actions.searchByQuery.mock.calls[0][1]).toBe('search');
      });

      it('sorts by fields', () => {
        const findSortItem = () => findSortDropdown().find('.dropdown-item');
        findSortItem().trigger('click');
        expect(actions.sortByField).toHaveBeenCalled();
      });

      it('filters by status', () => {
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
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorListTable().exists()).toBe(false);
      expect(dropdownsArray().length).toBe(0);
    });
  });

  describe('When the integrated tracking diabled alert should be shown', () => {
    beforeEach(() => {
      mountComponent({
        showIntegratedTrackingDisabledAlert: true,
        stubs: {
          GlAlert: false,
        },
      });
    });

    it('shows the alert box', () => {
      expect(findIntegratedDisabledAlert().exists()).toBe(true);
    });

    describe('when alert is dismissed', () => {
      it('hides the alert box', async () => {
        findIntegratedDisabledAlert().vm.$emit('dismiss');

        await nextTick();

        expect(findIntegratedDisabledAlert().exists()).toBe(false);
      });
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

  describe('when the resolve button is clicked with non numberic error id', () => {
    beforeEach(() => {
      store.state.list.loading = false;
      store.state.list.errors = [
        {
          id: 'abc',
          title: 'PG::ConnectionBad: FATAL',
          type: 'error',
          userCount: 0,
          count: '53',
          firstSeen: '2019-05-30T07:21:46Z',
          lastSeen: '2019-11-06T03:21:39Z',
          status: 'unresolved',
        },
      ];

      mountComponent({
        stubs: {
          GlTable: false,
          GlLink: false,
        },
      });
    });

    it('should show about:blank link', () => {
      findErrorActions().vm.$emit('update-issue-status', {
        errorId: 'abc',
        status: 'resolved',
      });

      expect(actions.updateStatus).toHaveBeenCalledWith(expect.anything(), {
        endpoint: 'about:blank',
        status: 'resolved',
      });
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
      const emptyStateComponent = wrapper.findComponent(GlEmptyState);
      const emptyStatePrimaryDescription = emptyStateComponent.find('span', {
        exactText: 'Monitor your errors directly in GitLab.',
      });
      const emptyStateSecondaryDescription = emptyStateComponent.find('span', {
        exactText: 'Error tracking is currently in',
      });
      const emptyStateLinks = emptyStateComponent.findAll('a');
      expect(emptyStateComponent.isVisible()).toBe(true);
      expect(emptyStatePrimaryDescription.exists()).toBe(true);
      expect(emptyStateSecondaryDescription.exists()).toBe(true);
      expect(emptyStateLinks.at(0).attributes('href')).toBe(
        '/help/operations/error_tracking.html#integrated-error-tracking',
      );
      expect(emptyStateLinks.at(1).attributes('href')).toBe(
        'https://about.gitlab.com/handbook/product/gitlab-the-product/#open-beta',
      );
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

    it('shows items', async () => {
      store.state.list.recentSearches = ['great', 'search'];

      await nextTick();
      const dropdownItems = wrapper.findAll('.filtered-search-box li');
      expect(dropdownItems.length).toBe(3);
      expect(dropdownItems.at(0).text()).toBe('great');
      expect(dropdownItems.at(1).text()).toBe('search');
    });

    describe('clear', () => {
      const clearRecentButton = () => wrapper.findComponent({ ref: 'clearRecentSearches' });

      it('is hidden when list empty', () => {
        store.state.list.recentSearches = [];

        expect(clearRecentButton().exists()).toBe(false);
      });

      it('is visible when list has items', async () => {
        store.state.list.recentSearches = ['some', 'searches'];

        await nextTick();
        expect(clearRecentButton().exists()).toBe(true);
        expect(clearRecentButton().text()).toBe('Clear recent searches');
      });

      it('clears items on click', async () => {
        store.state.list.recentSearches = ['some', 'searches'];

        await nextTick();
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
    describe('and previous cursor is not available', () => {
      beforeEach(() => {
        store.state.list.loading = false;
        delete store.state.list.pagination.previous;
        mountComponent();
      });

      it('disables Prev button in the pagination', () => {
        expect(findPagination().props('prevPage')).toBe(null);
        expect(findPagination().props('nextPage')).not.toBe(null);
      });
    });
    describe('and next cursor is not available', () => {
      beforeEach(() => {
        store.state.list.loading = false;
        delete store.state.list.pagination.next;
        mountComponent();
      });

      it('disables Next button in the pagination', () => {
        expect(findPagination().props('prevPage')).not.toBe(null);
        expect(findPagination().props('nextPage')).toBe(null);
      });
    });
    describe('and the user is not on the first page', () => {
      describe('and the previous button is clicked', () => {
        const currentPage = 2;

        beforeEach(() => {
          store.state.list.loading = false;
          mountComponent({
            stubs: {
              GlTable: false,
              GlPagination: false,
            },
          });
          findPagination().vm.$emit('input', currentPage);
        });

        it('fetches the previous page of results', () => {
          expect(wrapper.find('.prev-page-item').attributes('aria-disabled')).toBe(undefined);
          findPagination().vm.$emit('input', currentPage - 1);
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
          GlDropdown: false,
          GlDropdownItem: false,
        },
      });
    });

    it('should track list views', () => {
      const { category, action } = trackErrorListViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track status updates', async () => {
      const status = 'ignored';
      findErrorActions().vm.$emit('update-issue-status', {
        errorId: 1,
        status,
      });

      await nextTick();

      const { category, action } = trackErrorStatusUpdateOptions(status);
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track error filter', () => {
      const findStatusFilter = () => findStatusFilterDropdown().find('.dropdown-item');
      findStatusFilter().trigger('click');
      const { category, action } = trackErrorStatusFilterOptions('unresolved');
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });

    it('should track error sorting', () => {
      const findSortItem = () => findSortDropdown().find('.dropdown-item');
      findSortItem().trigger('click');
      const { category, action } = trackErrorSortedByField('last_seen');
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
