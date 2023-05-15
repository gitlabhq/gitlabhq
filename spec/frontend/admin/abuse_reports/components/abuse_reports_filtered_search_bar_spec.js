import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { redirectTo, updateHistory } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import AbuseReportsFilteredSearchBar from '~/admin/abuse_reports/components/abuse_reports_filtered_search_bar.vue';
import {
  FILTERED_SEARCH_TOKENS,
  FILTERED_SEARCH_TOKEN_USER,
  FILTERED_SEARCH_TOKEN_REPORTER,
  FILTERED_SEARCH_TOKEN_STATUS,
  FILTERED_SEARCH_TOKEN_CATEGORY,
  DEFAULT_SORT,
  SORT_OPTIONS,
} from '~/admin/abuse_reports/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { buildFilteredSearchCategoryToken } from '~/admin/abuse_reports/utils';

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    __esModule: true,
    ...urlUtility,
    redirectTo: jest.fn(),
    updateHistory: jest.fn(),
  };
});

describe('AbuseReportsFilteredSearchBar', () => {
  let wrapper;

  const CATEGORIES = ['spam', 'phishing'];

  const createComponent = () => {
    wrapper = shallowMount(AbuseReportsFilteredSearchBar, {
      provide: { categories: CATEGORIES },
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  beforeEach(() => {
    setWindowLocation('https://localhost');
  });

  it('passes correct props to `FilteredSearchBar` component', () => {
    createComponent();

    const categoryToken = buildFilteredSearchCategoryToken(CATEGORIES);

    expect(findFilteredSearchBar().props()).toMatchObject({
      namespace: 'abuse_reports',
      recentSearchesStorageKey: 'abuse_reports',
      searchInputPlaceholder: 'Filter reports',
      tokens: [...FILTERED_SEARCH_TOKENS, categoryToken],
      initialSortBy: DEFAULT_SORT,
      sortOptions: SORT_OPTIONS,
    });
  });

  it.each([undefined, 'invalid'])(
    'sets status=open query when initial status query is %s',
    (status) => {
      if (status) {
        setWindowLocation(`?status=${status}`);
      }

      createComponent();

      expect(updateHistory).toHaveBeenCalledWith({
        url: 'https://localhost/?status=open',
        replace: true,
      });

      expect(findFilteredSearchBar().props('initialFilterValue')).toMatchObject([
        {
          type: FILTERED_SEARCH_TOKEN_STATUS.type,
          value: { data: 'open', operator: '=' },
        },
      ]);
    },
  );

  it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
    setWindowLocation('?status=closed&user=mr_abuser&reporter=ms_nitch');

    createComponent();

    expect(findFilteredSearchBar().props('initialFilterValue')).toMatchObject([
      {
        type: FILTERED_SEARCH_TOKEN_USER.type,
        value: { data: 'mr_abuser', operator: '=' },
      },
      {
        type: FILTERED_SEARCH_TOKEN_REPORTER.type,
        value: { data: 'ms_nitch', operator: '=' },
      },
      {
        type: FILTERED_SEARCH_TOKEN_STATUS.type,
        value: { data: 'closed', operator: '=' },
      },
    ]);
  });

  describe('initial sort', () => {
    it.each(
      SORT_OPTIONS.flatMap(({ sortDirection: { descending, ascending } }) => [
        descending,
        ascending,
      ]),
    )(
      'parses sort=%s query and passes it to `FilteredSearchBar` component as initialSortBy',
      (sortBy) => {
        setWindowLocation(`?sort=${sortBy}`);

        createComponent();

        expect(findFilteredSearchBar().props('initialSortBy')).toEqual(sortBy);
      },
    );

    it(`uses ${DEFAULT_SORT} as initialSortBy when sort query param is invalid`, () => {
      setWindowLocation(`?sort=unknown`);

      createComponent();

      expect(findFilteredSearchBar().props('initialSortBy')).toEqual(DEFAULT_SORT);
    });
  });

  describe('onFilter', () => {
    const USER_FILTER_TOKEN = {
      type: FILTERED_SEARCH_TOKEN_USER.type,
      value: { data: 'mr_abuser', operator: '=' },
    };
    const REPORTER_FILTER_TOKEN = {
      type: FILTERED_SEARCH_TOKEN_REPORTER.type,
      value: { data: 'ms_nitch', operator: '=' },
    };
    const STATUS_FILTER_TOKEN = {
      type: FILTERED_SEARCH_TOKEN_STATUS.type,
      value: { data: 'open', operator: '=' },
    };
    const CATEGORY_FILTER_TOKEN = {
      type: FILTERED_SEARCH_TOKEN_CATEGORY.type,
      value: { data: 'spam', operator: '=' },
    };

    const createComponentAndFilter = (filterTokens, initialLocation) => {
      if (initialLocation) {
        setWindowLocation(initialLocation);
      }

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);
    };

    it.each([USER_FILTER_TOKEN, REPORTER_FILTER_TOKEN, STATUS_FILTER_TOKEN, CATEGORY_FILTER_TOKEN])(
      'redirects with $type query param',
      (filterToken) => {
        createComponentAndFilter([filterToken]);
        const { type, value } = filterToken;
        expect(redirectTo).toHaveBeenCalledWith(`https://localhost/?${type}=${value.data}`); // eslint-disable-line import/no-deprecated
      },
    );

    it('ignores search query param', () => {
      const searchFilterToken = { type: FILTERED_SEARCH_TERM, value: { data: 'ignored' } };
      createComponentAndFilter([USER_FILTER_TOKEN, searchFilterToken]);
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser'); // eslint-disable-line import/no-deprecated
    });

    it('redirects without page query param', () => {
      createComponentAndFilter([USER_FILTER_TOKEN], '?page=2');
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser'); // eslint-disable-line import/no-deprecated
    });

    it('redirects with existing sort query param', () => {
      createComponentAndFilter([USER_FILTER_TOKEN], `?sort=${DEFAULT_SORT}`);
      // eslint-disable-next-line import/no-deprecated
      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?user=mr_abuser&sort=${DEFAULT_SORT}`,
      );
    });
  });

  describe('onSort', () => {
    const SORT_VALUE = 'updated_at_asc';
    const EXISTING_QUERY = 'status=closed&user=mr_abuser';

    const createComponentAndSort = (initialLocation) => {
      setWindowLocation(initialLocation);
      createComponent();
      findFilteredSearchBar().vm.$emit('onSort', SORT_VALUE);
    };

    it('redirects to URL with existing query params and the sort query param', () => {
      createComponentAndSort(`?${EXISTING_QUERY}`);

      // eslint-disable-next-line import/no-deprecated
      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });

    it('redirects without page query param', () => {
      createComponentAndSort(`?${EXISTING_QUERY}&page=2`);

      // eslint-disable-next-line import/no-deprecated
      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });

    it('redirects with existing sort query param replaced with the new one', () => {
      createComponentAndSort(`?${EXISTING_QUERY}&sort=created_at_desc`);

      // eslint-disable-next-line import/no-deprecated
      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });
  });
});
