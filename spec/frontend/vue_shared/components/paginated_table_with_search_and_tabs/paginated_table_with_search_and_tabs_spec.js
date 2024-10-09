import { GlAlert, GlBadge, GlPagination, GlTabs, GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Tracking from '~/tracking';
import {
  OPERATORS_IS,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import PageWrapper from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import mockItems from './mocks/items.json';
import mockFilters from './mocks/items_filters.json';

const EmptyStateSlot = {
  template: '<div class="empty-state">Empty State</div>',
};

const HeaderActionsSlot = {
  template: '<div class="header-actions"><button>Action Button</button></div>',
};

const TitleSlot = {
  template: '<div>Page Wrapper Title</div>',
};

const TableSlot = {
  template: '<table class="gl-table"></table>',
};

const itemsCount = {
  opened: 24,
  closed: 10,
  all: 34,
};

const ITEMS_STATUS_TABS = [
  {
    title: 'Opened items',
    status: 'OPENED',
    filters: ['opened'],
  },
  {
    title: 'Closed items',
    status: 'CLOSED',
    filters: ['closed'],
  },
  {
    title: 'All items',
    status: 'ALL',
    filters: ['all'],
  },
];

describe('AlertManagementEmptyState', () => {
  let wrapper;

  function mountComponent({ props = {} } = {}) {
    wrapper = mount(PageWrapper, {
      provide: {
        projectPath: '/link',
      },
      propsData: {
        items: [],
        itemsCount: {},
        pageInfo: {},
        statusTabs: [],
        loading: false,
        showItems: false,
        showErrorMsg: false,
        trackViewsOptions: {},
        i18n: {},
        serverErrorMessage: '',
        filterSearchKey: '',
        ...props,
      },
      slots: {
        'empty-state': EmptyStateSlot,
        'header-actions': HeaderActionsSlot,
        title: TitleSlot,
        table: TableSlot,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  const EmptyState = () => wrapper.find('.empty-state');
  const ItemsTable = () => wrapper.find('.gl-table');
  const ErrorAlert = () => wrapper.findComponent(GlAlert);
  const Pagination = () => wrapper.findComponent(GlPagination);
  const ActionButton = () => wrapper.find('.header-actions > button');
  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findStatusFilterTabs = () => wrapper.findAllComponents(GlTab);
  const findStatusTabs = () => wrapper.findComponent(GlTabs);
  const findStatusFilterBadge = () => wrapper.findAllComponents(GlBadge);

  const handleFilterItems = (filters) => {
    findFilteredSearchBar().vm.$emit('onFilter', filters);
    return nextTick();
  };

  describe('Snowplow tracking', () => {
    const category = 'category';
    const action = 'action';

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mountComponent({
        props: { trackViewsOptions: { category, action } },
      });
    });

    it('should track the items list page views', () => {
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });

  describe('Page wrapper with no items', () => {
    it('renders the empty state if there are no items present', () => {
      expect(EmptyState().exists()).toBe(true);
    });
  });

  describe('Page wrapper with items', () => {
    it('renders the tabs selection with valid tabs', () => {
      mountComponent({
        props: {
          statusTabs: [
            { status: 'opened', title: 'Open' },
            { status: 'closed', title: 'Closed' },
          ],
        },
      });

      expect(findStatusTabs().exists()).toBe(true);
    });

    it('renders the header action buttons if present', () => {
      expect(ActionButton().exists()).toBe(true);
    });

    it('renders a error alert if there are errors', () => {
      mountComponent({
        props: { showErrorMsg: true },
      });

      expect(ErrorAlert().exists()).toBe(true);
    });

    it('renders a table of items if items are present', () => {
      mountComponent({
        props: { showItems: true, items: mockItems },
      });

      expect(ItemsTable().exists()).toBe(true);
    });

    it('renders pagination if there the pagination info object has a next or previous page', () => {
      mountComponent({
        props: { pageInfo: { hasNextPage: true } },
      });

      expect(Pagination().exists()).toBe(true);
    });

    it('renders the filter set with the tokens according to the prop filterSearchTokens', () => {
      mountComponent({
        props: { filterSearchTokens: [TOKEN_TYPE_ASSIGNEE] },
      });

      expect(findFilteredSearchBar().exists()).toBe(true);
    });
  });

  describe('Status Filter Tabs', () => {
    beforeEach(() => {
      mountComponent({
        props: { items: mockItems, itemsCount, statusTabs: ITEMS_STATUS_TABS },
      });
    });

    it('should display filter tabs', () => {
      const tabs = findStatusFilterTabs().wrappers;

      tabs.forEach((tab, i) => {
        expect(tab.attributes('data-testid')).toContain(ITEMS_STATUS_TABS[i].status);
      });
    });

    it('should display filter tabs with items count badge for each status', () => {
      const tabs = findStatusFilterTabs().wrappers;
      const badges = findStatusFilterBadge();

      tabs.forEach((tab, i) => {
        const status = ITEMS_STATUS_TABS[i].status.toLowerCase();
        expect(tab.attributes('data-testid')).toContain(ITEMS_STATUS_TABS[i].status);
        expect(badges.at(i).text()).toContain(itemsCount[status].toString());
      });
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      mountComponent({
        props: {
          items: mockItems,
          itemsCount,
          statusTabs: ITEMS_STATUS_TABS,
          pageInfo: { hasNextPage: true },
        },
      });
    });

    it('should render pagination', () => {
      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });

    describe('prevPage', () => {
      it('returns prevPage button', async () => {
        findPagination().vm.$emit('input', 3);

        await nextTick();
        expect(findPagination().find('[data-testid="gl-pagination-prev"]').text()).toBe('Previous');
      });

      it('returns prevPage number', async () => {
        findPagination().vm.$emit('input', 3);

        await nextTick();
        expect(findPagination().props('prevPage')).toBe(2);
      });

      it('returns 0 when it is the first page', async () => {
        findPagination().vm.$emit('input', 1);

        await nextTick();
        expect(findPagination().props('prevPage')).toBe(0);
      });
    });

    describe('nextPage', () => {
      it('returns nextPage button', async () => {
        findPagination().vm.$emit('input', 3);

        await nextTick();
        expect(findPagination().find('[data-testid="gl-pagination-next"]').text()).toBe('Next');
      });

      it('returns nextPage number', async () => {
        mountComponent({
          props: {
            items: mockItems,
            itemsCount,
            statusTabs: ITEMS_STATUS_TABS,
            pageInfo: { hasNextPage: true },
          },
        });
        findPagination().vm.$emit('input', 1);

        await nextTick();
        expect(findPagination().props('nextPage')).toBe(2);
      });

      it('returns `null` when currentPage is already last page', async () => {
        findStatusTabs().vm.$emit('input', 1);
        findPagination().vm.$emit('input', 1);
        await nextTick();
        expect(findPagination().props('nextPage')).toBeNull();
      });
    });
  });

  describe('Filtered search component', () => {
    beforeEach(() => {
      mountComponent({
        props: {
          items: mockItems,
          itemsCount,
          statusTabs: ITEMS_STATUS_TABS,
          filterSearchKey: 'items',
        },
      });
    });

    it('renders the search component for incidents', () => {
      const filteredSearchBar = findFilteredSearchBar();

      expect(filteredSearchBar.props('tokens')).toEqual([
        {
          type: TOKEN_TYPE_AUTHOR,
          icon: 'user',
          title: TOKEN_TITLE_AUTHOR,
          unique: true,
          symbol: '@',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS,
          fetchPath: '/link',
          fetchUsers: expect.any(Function),
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          unique: true,
          symbol: '@',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS,
          fetchPath: '/link',
          fetchUsers: expect.any(Function),
        },
      ]);
      expect(filteredSearchBar.props('recentSearchesStorageKey')).toBe('items');
    });

    it('returns correctly applied filter search values', async () => {
      const searchTerm = 'foo';
      await handleFilterItems([{ type: 'filtered-search-term', value: { data: searchTerm } }]);
      await nextTick();
      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([searchTerm]);
    });

    it('updates props tied to getIncidents GraphQL query', async () => {
      await handleFilterItems(mockFilters);

      const [
        {
          value: { data: authorUsername },
        },
        {
          value: { data: assigneeUsername },
        },
        searchTerm,
      ] = findFilteredSearchBar().props('initialFilterValue');

      expect(authorUsername).toBe('root');
      expect(assigneeUsername).toEqual('root2');
      expect(searchTerm).toBe(mockFilters[2].value.data);
    });

    it('updates props `searchTerm` and `authorUsername` with empty values when passed filters param is empty', async () => {
      await handleFilterItems([]);
      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([]);
    });
  });
});
