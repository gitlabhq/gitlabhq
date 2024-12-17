import {
  GlEmptyState,
  GlLoadingIcon,
  GlForm,
  GlFormInput,
  GlPagination,
  GlDropdown,
  GlDropdownItem,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import ErrorTrackingActions from '~/error_tracking/components/error_tracking_actions.vue';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import TimelineChart from '~/error_tracking/components/timeline_chart.vue';
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
    integratedErrorTrackingEnabled = false,
    listPath = '/error_tracking',

    stubs = {},
  } = {}) {
    wrapper = extendedWrapper(
      mount(ErrorTrackingList, {
        store,
        propsData: {
          indexPath: '/path',
          listPath,
          projectPath: 'project/test',
          enableErrorTrackingLink: '/link',
          userCanEnableErrorTracking,
          errorTrackingEnabled,
          integratedErrorTrackingEnabled,
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

    it('shows user count', () => {
      expect(findErrorListTable().find('thead').text()).toContain('Users');
    });

    describe.each([
      ['/test-project/-/error_tracking'],
      ['/test-project/-/error_tracking/'], // handles leading '/' https://gitlab.com/gitlab-org/gitlab/-/issues/430211
    ])('details link', (url) => {
      beforeEach(() => {
        mountComponent({
          listPath: url,
          stubs: {
            GlTable: false,
            GlLink: false,
          },
        });
      });
      it('each error in a list should have a link to the error page', () => {
        const errorTitle = wrapper.findAll('tbody tr a');

        errorTitle.wrappers.forEach((_, index) => {
          expect(errorTitle.at(index).attributes('href')).toEqual(
            `/test-project/-/error_tracking/${errorsList[index].id}/details`,
          );
        });
      });
    });

    it('each error in the list should have an action button set', () => {
      findErrorListRows().wrappers.forEach((row) => {
        expect(row.findComponent(ErrorTrackingActions).exists()).toBe(true);
      });
    });

    describe('timeline graph', () => {
      it('should show the timeline chart', () => {
        findErrorListRows().wrappers.forEach((row, index) => {
          expect(row.findComponent(TimelineChart).exists()).toBe(true);
          const mockFrequency = errorsList[index].frequency;
          expect(row.findComponent(TimelineChart).props('timelineData')).toEqual(mockFrequency);
        });
      });

      it('should not show the timeline chart if frequency data does not exist', () => {
        store.state.list.errors = errorsList.map((e) => ({ ...e, frequency: undefined }));
        mountComponent({
          stubs: {
            GlTable: false,
            GlLink: false,
          },
        });

        findErrorListRows().wrappers.forEach((row) => {
          expect(row.findComponent(TimelineChart).exists()).toBe(false);
        });
      });
    });

    describe('filtering', () => {
      const findSearchBox = () => wrapper.findComponent(GlFormInput);
      const findGlForm = () => wrapper.findComponent(GlForm);

      it('shows search box & sort dropdown', () => {
        expect(findSearchBox().exists()).toBe(true);
        expect(findSortDropdown().exists()).toBe(true);
      });

      it('searches by query', () => {
        findSearchBox().vm.$emit('input', 'search');
        findGlForm().vm.$emit('submit', { preventDefault: () => {} });
        expect(actions.searchByQuery.mock.calls[0][1]).toBe('search');
      });

      it('sorts by fields', () => {
        const findSortItem = () => findSortDropdown().findComponent(GlDropdownItem);
        findSortItem().vm.$emit('click');
        expect(actions.sortByField).toHaveBeenCalled();
      });

      it('filters by status', () => {
        const findStatusFilter = () => findStatusFilterDropdown().findComponent(GlDropdownItem);
        findStatusFilter().vm.$emit('click');
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
        await findIntegratedDisabledAlert().vm.$emit('dismiss');

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
      const emptyStateLinks = emptyStateComponent.findAll('a');
      expect(emptyStateComponent.isVisible()).toBe(true);
      expect(emptyStatePrimaryDescription.exists()).toBe(true);
      expect(emptyStateLinks.at(0).attributes('href')).toBe(
        '/help/operations/integrated_error_tracking',
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
      const dropdownItems = wrapper.findAll('[data-testid="recent-searches-dropdown"] li');
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
          expect(
            wrapper.find('[data-testid="gl-pagination-prev"]').attributes('aria-disabled'),
          ).toBe(undefined);
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
      store.state.list.loading = false;
      store.state.list.errors = errorsList;
    });

    describe.each([true, false])(`when integratedErrorTracking is %s`, (integrated) => {
      const category = 'Error Tracking';
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      beforeEach(() => {
        mountComponent({
          stubs: {
            GlTable: false,
            GlLink: false,
          },
          integratedErrorTrackingEnabled: integrated,
        });
      });

      it('should track list views', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'view_errors_list',
          {
            variant: integrated ? 'integrated' : 'external',
          },
          category,
        );
      });

      it('should track status updates', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        const status = 'ignored';
        findErrorActions().vm.$emit('update-issue-status', {
          errorId: 1,
          status,
        });
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'update_ignored_status',
          {
            variant: integrated ? 'integrated' : 'external',
          },
          category,
        );
      });

      it('should track error filter', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        const findStatusFilter = () => findStatusFilterDropdown().findComponent(GlDropdownItem);
        findStatusFilter().vm.$emit('click');

        expect(trackEventSpy).toHaveBeenCalledWith(
          'filter_unresolved_status',
          {
            variant: integrated ? 'integrated' : 'external',
          },
          category,
        );
      });

      it('should track error sorting', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        const findSortItem = () => findSortDropdown().findComponent(GlDropdownItem);
        findSortItem().vm.$emit('click');

        expect(trackEventSpy).toHaveBeenCalledWith(
          'sort_by_last_seen',
          {
            variant: integrated ? 'integrated' : 'external',
          },
          category,
        );
      });
    });
  });
});
