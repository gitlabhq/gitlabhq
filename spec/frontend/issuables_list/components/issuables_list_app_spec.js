import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlPagination, GlSkeletonLoading } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import flash from '~/flash';
import IssuablesListApp from '~/issuables_list/components/issuables_list_app.vue';
import Issuable from '~/issuables_list/components/issuable.vue';
import issueablesEventBus from '~/issuables_list/eventhub';
import { PAGE_SIZE, PAGE_SIZE_MANUAL, RELATIVE_POSITION } from '~/issuables_list/constants';

jest.mock('~/flash', () => jest.fn());
jest.mock('~/issuables_list/eventhub');

const TEST_LOCATION = `${TEST_HOST}/issues`;
const TEST_ENDPOINT = '/issues';
const TEST_CREATE_ISSUES_PATH = '/createIssue';
const TEST_EMPTY_SVG_PATH = '/emptySvg';

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

  const setupApiMock = cb => {
    apiSpy = jest.fn(cb);

    mockAxios.onGet(TEST_ENDPOINT).reply(cfg => apiSpy(cfg));
  };

  const factory = (props = { sortKey: 'priority' }) => {
    wrapper = shallowMount(IssuablesListApp, {
      propsData: {
        endpoint: TEST_ENDPOINT,
        createIssuePath: TEST_CREATE_ISSUES_PATH,
        emptySvgPath: TEST_EMPTY_SVG_PATH,
        ...props,
      },
      attachToDocument: true,
    });
  };

  const findLoading = () => wrapper.find(GlSkeletonLoading);
  const findIssuables = () => wrapper.findAll(Issuable);
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
      expect(flash).toHaveBeenCalledTimes(1);
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
        createIssuePath: TEST_CREATE_ISSUES_PATH,
        emptySvgPath: TEST_EMPTY_SVG_PATH,

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
        expect(wrapper.contains(GlEmptyState)).toBe(false);
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
      expect(wrapper.vm.selection).toEqual({ '1': true });
      wrapper.vm.onSelectIssuable({ issuable: i0, selected: true });
      expect(wrapper.vm.selection).toEqual({ '1': true, '0': true });
      wrapper.vm.onSelectIssuable({ issuable: i2, selected: true });
      expect(wrapper.vm.selection).toEqual({ '1': true, '0': true, '2': true });
      wrapper.vm.onSelectIssuable({ issuable: i2, selected: true });
      expect(wrapper.vm.selection).toEqual({ '1': true, '0': true, '2': true });
      wrapper.vm.onSelectIssuable({ issuable: i0, selected: false });
      expect(wrapper.vm.selection).toEqual({ '1': true, '2': true });
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
    const query =
      '?assignee_username=root&author_username=root&confidential=yes&label_name%5B%5D=Aquapod&label_name%5B%5D=Astro&milestone_title=v3.0&my_reaction_emoji=airplane&scope=all&sort=priority&state=opened&utf8=%E2%9C%93&weight=0';
    const expectedFilters = {
      assignee_username: 'root',
      author_username: 'root',
      confidential: 'yes',
      my_reaction_emoji: 'airplane',
      scope: 'all',
      state: 'opened',
      utf8: '✓',
      weight: '0',
      milestone: 'v3.0',
      labels: 'Aquapod,Astro',
      order_by: 'milestone_due',
      sort: 'desc',
    };

    beforeEach(() => {
      window.location.href = `${TEST_LOCATION}${query}`;
      window.location.search = query;
      setupApiMock(() => [200, MOCK_ISSUES.slice(0)]);
      factory({ sortKey: 'milestone_due_desc' });
      return waitForPromises();
    });

    it('applies filters and sorts', () => {
      expect(wrapper.vm.hasFilters).toBe(true);
      expect(wrapper.vm.filters).toEqual(expectedFilters);

      expect(apiSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          params: {
            ...expectedFilters,
            with_labels_details: true,
            page: 1,
            per_page: PAGE_SIZE,
          },
        }),
      );
    });

    it('passes the base url to issuable', () => {
      expect(findFirstIssuable().props('baseUrl')).toEqual(TEST_LOCATION);
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
      expect(findFirstIssuable().props('baseUrl')).toEqual(TEST_LOCATION);
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
});
