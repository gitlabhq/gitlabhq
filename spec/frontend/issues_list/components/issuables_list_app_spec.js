import {
  GlEmptyState,
  GlPagination,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import Issuable from '~/issues_list/components/issuable.vue';
import IssuablesListApp from '~/issues_list/components/issuables_list_app.vue';
import { PAGE_SIZE, PAGE_SIZE_MANUAL, RELATIVE_POSITION } from '~/issues_list/constants';
import issueablesEventBus from '~/issues_list/eventhub';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/flash');
jest.mock('~/issues_list/eventhub');
jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: () => {},
}));

const TEST_LOCATION = `${TEST_HOST}/issues`;
const TEST_ENDPOINT = '/issues';
const TEST_CREATE_ISSUES_PATH = '/createIssue';
const TEST_SVG_PATH = '/emptySvg';

const setUrl = (query) => {
  window.location.href = `${TEST_LOCATION}${query}`;
  window.location.search = query;
};

const MOCK_ISSUES = Array(PAGE_SIZE_MANUAL)
  .fill(0)
  .map((_, i) => ({
    id: i,
    web_url: `url${i}`,
  }));

describe('Issuables list component', () => {
  let oldLocation;
  let mockAxios;
  let wrapper;
  let apiSpy;

  const setupApiMock = (cb) => {
    apiSpy = jest.fn(cb);

    mockAxios.onGet(TEST_ENDPOINT).reply((cfg) => apiSpy(cfg));
  };

  const factory = (props = { sortKey: 'priority' }) => {
    const emptyStateMeta = {
      createIssuePath: TEST_CREATE_ISSUES_PATH,
      svgPath: TEST_SVG_PATH,
    };

    wrapper = shallowMount(IssuablesListApp, {
      propsData: {
        endpoint: TEST_ENDPOINT,
        emptyStateMeta,
        ...props,
      },
    });
  };

  const findLoading = () => wrapper.find(GlSkeletonLoading);
  const findIssuables = () => wrapper.findAll(Issuable);
  const findFilteredSearchBar = () => wrapper.find(FilteredSearchBar);
  const findFirstIssuable = () => findIssuables().wrappers[0];
  const findEmptyState = () => wrapper.find(GlEmptyState);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);

    oldLocation = window.location;
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { href: '', search: '' },
    });
    window.location.href = TEST_LOCATION;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
    window.location = oldLocation;
  });

  describe('with failed issues response', () => {
    beforeEach(() => {
      setupApiMock(() => [500]);

      factory();

      return waitForPromises();
    });

    it('does not show loading', () => {
      expect(wrapper.vm.loading).toBe(false);
    });

    it('flashes an error', () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
    });
  });

  describe('with successful issues response', () => {
    beforeEach(() => {
      setupApiMock(() => [
        200,
        MOCK_ISSUES.slice(0, PAGE_SIZE),
        {
          'x-total': 100,
          'x-page': 2,
        },
      ]);
    });

    it('has default props and data', () => {
      factory();
      expect(wrapper.vm).toMatchObject({
        // Props
        canBulkEdit: false,
        emptyStateMeta: {
          createIssuePath: TEST_CREATE_ISSUES_PATH,
          svgPath: TEST_SVG_PATH,
        },
        // Data
        filters: {
          state: 'opened',
        },
        isBulkEditing: false,
        issuables: [],
        loading: true,
        page: 1,
        selection: {},
        totalItems: 0,
      });
    });

    it('does not call API until mounted', () => {
      factory();
      expect(apiSpy).not.toHaveBeenCalled();
    });

    describe('when mounted', () => {
      beforeEach(() => {
        factory();
      });

      it('calls API', () => {
        expect(apiSpy).toHaveBeenCalled();
      });

      it('shows loading', () => {
        expect(findLoading().exists()).toBe(true);
        expect(findIssuables().length).toBe(0);
        expect(findEmptyState().exists()).toBe(false);
      });
    });

    describe('when finished loading', () => {
      beforeEach(() => {
        factory();

        return waitForPromises();
      });

      it('does not display empty state', () => {
        expect(wrapper.vm.issuables.length).toBeGreaterThan(0);
        expect(wrapper.vm.emptyState).toEqual({});
        expect(wrapper.find(GlEmptyState).exists()).toBe(false);
      });

      it('sets the proper page and total items', () => {
        expect(wrapper.vm.totalItems).toBe(100);
        expect(wrapper.vm.page).toBe(2);
      });

      it('renders one page of issuables and pagination', () => {
        expect(findIssuables().length).toBe(PAGE_SIZE);
        expect(wrapper.find(GlPagination).exists()).toBe(true);
      });
    });

    it('does not render FilteredSearchBar', () => {
      factory();

      expect(findFilteredSearchBar().exists()).toBe(false);
    });
  });

  describe('with bulk editing enabled', () => {
    beforeEach(() => {
      issueablesEventBus.$on.mockReset();
      issueablesEventBus.$emit.mockReset();

      setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
      factory({ canBulkEdit: true });

      return waitForPromises();
    });

    it('is not enabled by default', () => {
      expect(wrapper.vm.isBulkEditing).toBe(false);
    });

    it('does not select issues by default', () => {
      expect(wrapper.vm.selection).toEqual({});
    });

    it('"Select All" checkbox toggles all visible issuables"', () => {
      wrapper.vm.onSelectAll();
      expect(wrapper.vm.selection).toEqual(
        wrapper.vm.issuables.reduce((acc, i) => ({ ...acc, [i.id]: true }), {}),
      );

      wrapper.vm.onSelectAll();
      expect(wrapper.vm.selection).toEqual({});
    });

    it('"Select All checkbox" selects all issuables if only some are selected"', () => {
      wrapper.vm.selection = { [wrapper.vm.issuables[0].id]: true };
      wrapper.vm.onSelectAll();
      expect(wrapper.vm.selection).toEqual(
        wrapper.vm.issuables.reduce((acc, i) => ({ ...acc, [i.id]: true }), {}),
      );
    });

    it('selects and deselects issuables', () => {
      const [i0, i1, i2] = wrapper.vm.issuables;

      expect(wrapper.vm.selection).toEqual({});
      wrapper.vm.onSelectIssuable({ issuable: i0, selected: false });
      expect(wrapper.vm.selection).toEqual({});
      wrapper.vm.onSelectIssuable({ issuable: i1, selected: true });
      expect(wrapper.vm.selection).toEqual({ 1: true });
      wrapper.vm.onSelectIssuable({ issuable: i0, selected: true });
      expect(wrapper.vm.selection).toEqual({ 1: true, 0: true });
      wrapper.vm.onSelectIssuable({ issuable: i2, selected: true });
      expect(wrapper.vm.selection).toEqual({ 1: true, 0: true, 2: true });
      wrapper.vm.onSelectIssuable({ issuable: i2, selected: true });
      expect(wrapper.vm.selection).toEqual({ 1: true, 0: true, 2: true });
      wrapper.vm.onSelectIssuable({ issuable: i0, selected: false });
      expect(wrapper.vm.selection).toEqual({ 1: true, 2: true });
    });

    it('broadcasts a message to the bulk edit sidebar when a value is added to selection', () => {
      issueablesEventBus.$emit.mockReset();
      const i1 = wrapper.vm.issuables[1];

      wrapper.vm.onSelectIssuable({ issuable: i1, selected: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(issueablesEventBus.$emit).toHaveBeenCalledTimes(1);
        expect(issueablesEventBus.$emit).toHaveBeenCalledWith('issuables:updateBulkEdit');
      });
    });

    it('does not broadcast a message to the bulk edit sidebar when a value is not added to selection', () => {
      issueablesEventBus.$emit.mockReset();

      return wrapper.vm
        .$nextTick()
        .then(waitForPromises)
        .then(() => {
          const i1 = wrapper.vm.issuables[1];

          wrapper.vm.onSelectIssuable({ issuable: i1, selected: false });
        })
        .then(wrapper.vm.$nextTick)
        .then(() => {
          expect(issueablesEventBus.$emit).toHaveBeenCalledTimes(0);
        });
    });

    it('listens to a message to toggle bulk editing', () => {
      expect(wrapper.vm.isBulkEditing).toBe(false);
      expect(issueablesEventBus.$on.mock.calls[0][0]).toBe('issuables:toggleBulkEdit');
      issueablesEventBus.$on.mock.calls[0][1](true); // Call the message handler

      return waitForPromises()
        .then(() => {
          expect(wrapper.vm.isBulkEditing).toBe(true);
          issueablesEventBus.$on.mock.calls[0][1](false);
        })
        .then(() => {
          expect(wrapper.vm.isBulkEditing).toBe(false);
        });
    });
  });

  describe('with query params in window.location', () => {
    const expectedFilters = {
      assignee_username: 'root',
      author_username: 'root',
      confidential: 'yes',
      my_reaction_emoji: 'airplane',
      scope: 'all',
      state: 'opened',
      weight: '0',
      milestone: 'v3.0',
      labels: 'Aquapod,Astro',
      order_by: 'milestone_due',
      sort: 'desc',
    };

    describe('when page is not present in params', () => {
      const query =
        '?assignee_username=root&author_username=root&confidential=yes&label_name%5B%5D=Aquapod&label_name%5B%5D=Astro&milestone_title=v3.0&my_reaction_emoji=airplane&scope=all&sort=priority&state=opened&weight=0&not[label_name][]=Afterpod&not[milestone_title][]=13';

      beforeEach(() => {
        setUrl(query);

        setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
        factory({ sortKey: 'milestone_due_desc' });

        return waitForPromises();
      });

      afterEach(() => {
        apiSpy.mockClear();
      });

      it('applies filters and sorts', () => {
        expect(wrapper.vm.hasFilters).toBe(true);
        expect(wrapper.vm.filters).toEqual({
          ...expectedFilters,
          'not[milestone]': ['13'],
          'not[labels]': ['Afterpod'],
        });

        expect(apiSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            params: {
              ...expectedFilters,
              with_labels_details: true,
              page: 1,
              per_page: PAGE_SIZE,
              'not[milestone]': ['13'],
              'not[labels]': ['Afterpod'],
            },
          }),
        );
      });

      it('passes the base url to issuable', () => {
        expect(findFirstIssuable().props('baseUrl')).toBe(TEST_LOCATION);
      });
    });

    describe('when page is present in the param', () => {
      const query =
        '?assignee_username=root&author_username=root&confidential=yes&label_name%5B%5D=Aquapod&label_name%5B%5D=Astro&milestone_title=v3.0&my_reaction_emoji=airplane&scope=all&sort=priority&state=opened&weight=0&page=3';

      beforeEach(() => {
        setUrl(query);

        setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
        factory({ sortKey: 'milestone_due_desc' });

        return waitForPromises();
      });

      afterEach(() => {
        apiSpy.mockClear();
      });

      it('applies filters and sorts', () => {
        expect(apiSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            params: {
              ...expectedFilters,
              with_labels_details: true,
              page: 3,
              per_page: PAGE_SIZE,
            },
          }),
        );
      });
    });
  });

  describe('with hash in window.location', () => {
    beforeEach(() => {
      window.location.href = `${TEST_LOCATION}#stuff`;
      setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
      factory();
      return waitForPromises();
    });

    it('passes the base url to issuable', () => {
      expect(findFirstIssuable().props('baseUrl')).toBe(TEST_LOCATION);
    });
  });

  describe('with manual sort', () => {
    beforeEach(() => {
      setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
      factory({ sortKey: RELATIVE_POSITION });
    });

    it('uses manual page size', () => {
      expect(apiSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          params: expect.objectContaining({
            per_page: PAGE_SIZE_MANUAL,
          }),
        }),
      );
    });
  });

  describe('with empty issues response', () => {
    beforeEach(() => {
      setupApiMock(() => [200, []]);
    });

    describe('with query in window location', () => {
      beforeEach(() => {
        window.location.search = '?weight=Any';

        factory();

        return waitForPromises().then(() => wrapper.vm.$nextTick());
      });

      it('should display "Sorry, your filter produced no results" if filters are too specific', () => {
        expect(findEmptyState().props('title')).toMatchSnapshot();
      });
    });

    describe('with closed state', () => {
      beforeEach(() => {
        window.location.search = '?state=closed';

        factory();

        return waitForPromises().then(() => wrapper.vm.$nextTick());
      });

      it('should display a message "There are no closed issues" if there are no closed issues', () => {
        expect(findEmptyState().props('title')).toMatchSnapshot();
      });
    });

    describe('with all state', () => {
      beforeEach(() => {
        window.location.search = '?state=all';

        factory();

        return waitForPromises().then(() => wrapper.vm.$nextTick());
      });

      it('should display a catch-all if there are no issues to show', () => {
        expect(findEmptyState().element).toMatchSnapshot();
      });
    });

    describe('with empty query', () => {
      beforeEach(() => {
        factory();

        return wrapper.vm.$nextTick().then(waitForPromises);
      });

      it('should display the message "There are no open issues"', () => {
        expect(findEmptyState().props('title')).toMatchSnapshot();
      });
    });
  });

  describe('when paginates', () => {
    const newPage = 3;

    describe('when total-items is defined in response headers', () => {
      beforeEach(() => {
        window.history.pushState = jest.fn();
        setupApiMock(() => [
          200,
          MOCK_ISSUES.slice(0, PAGE_SIZE),
          {
            'x-total': 100,
            'x-page': 2,
          },
        ]);

        factory();

        return waitForPromises();
      });

      afterEach(() => {
        // reset to original value
        window.history.pushState.mockRestore();
      });

      it('calls window.history.pushState one time', () => {
        // Trigger pagination
        wrapper.find(GlPagination).vm.$emit('input', newPage);

        expect(window.history.pushState).toHaveBeenCalledTimes(1);
      });

      it('sets params in the url', () => {
        // Trigger pagination
        wrapper.find(GlPagination).vm.$emit('input', newPage);

        expect(window.history.pushState).toHaveBeenCalledWith(
          {},
          '',
          `${TEST_LOCATION}?state=opened&order_by=priority&sort=asc&page=${newPage}`,
        );
      });
    });

    describe('when total-items is not defined in the headers', () => {
      const page = 2;
      const prevPage = page - 1;
      const nextPage = page + 1;

      beforeEach(() => {
        setupApiMock(() => [
          200,
          MOCK_ISSUES.slice(0, PAGE_SIZE),
          {
            'x-page': page,
          },
        ]);

        factory();

        return waitForPromises();
      });

      it('finds the correct props applied to GlPagination', () => {
        expect(wrapper.find(GlPagination).props()).toMatchObject({
          nextPage,
          prevPage,
          value: page,
        });
      });
    });
  });

  describe('when type is "jira"', () => {
    it('renders FilteredSearchBar', () => {
      factory({ type: 'jira' });

      expect(findFilteredSearchBar().exists()).toBe(true);
    });

    describe('initialSortBy', () => {
      const query = '?sort=updated_asc';

      it('sets default value', () => {
        factory({ type: 'jira' });

        expect(findFilteredSearchBar().props('initialSortBy')).toBe('created_desc');
      });

      it('sets value according to query', () => {
        setUrl(query);

        factory({ type: 'jira' });

        expect(findFilteredSearchBar().props('initialSortBy')).toBe('updated_asc');
      });
    });

    describe('initialFilterValue', () => {
      it('does not set value when no query', () => {
        factory({ type: 'jira' });

        expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([]);
      });

      it('sets value according to query', () => {
        const query = '?search=free+text';

        setUrl(query);

        factory({ type: 'jira' });

        expect(findFilteredSearchBar().props('initialFilterValue')).toEqual(['free text']);
      });
    });

    describe('on filter search', () => {
      beforeEach(() => {
        factory({ type: 'jira' });

        window.history.pushState = jest.fn();
      });

      afterEach(() => {
        window.history.pushState.mockRestore();
      });

      const emitOnFilter = (filter) => findFilteredSearchBar().vm.$emit('onFilter', filter);

      describe('empty filter', () => {
        const mockFilter = [];

        it('updates URL with correct params', () => {
          emitOnFilter(mockFilter);

          expect(window.history.pushState).toHaveBeenCalledWith(
            {},
            '',
            `${TEST_LOCATION}?state=opened`,
          );
        });
      });

      describe('filter with search term', () => {
        const mockFilter = [
          {
            type: 'filtered-search-term',
            value: { data: 'free' },
          },
        ];

        it('updates URL with correct params', () => {
          emitOnFilter(mockFilter);

          expect(window.history.pushState).toHaveBeenCalledWith(
            {},
            '',
            `${TEST_LOCATION}?state=opened&search=free`,
          );
        });
      });

      describe('filter with multiple search terms', () => {
        const mockFilter = [
          {
            type: 'filtered-search-term',
            value: { data: 'free' },
          },
          {
            type: 'filtered-search-term',
            value: { data: 'text' },
          },
        ];

        it('updates URL with correct params', () => {
          emitOnFilter(mockFilter);

          expect(window.history.pushState).toHaveBeenCalledWith(
            {},
            '',
            `${TEST_LOCATION}?state=opened&search=free+text`,
          );
        });
      });
    });
  });
});
