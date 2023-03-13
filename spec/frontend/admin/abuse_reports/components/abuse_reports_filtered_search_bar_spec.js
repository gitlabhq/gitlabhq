import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { redirectTo, updateHistory } from '~/lib/utils/url_utility';
import AbuseReportsFilteredSearchBar from '~/admin/abuse_reports/components/abuse_reports_filtered_search_bar.vue';
import {
  FILTERED_SEARCH_TOKENS,
  FILTERED_SEARCH_TOKEN_USER,
  FILTERED_SEARCH_TOKEN_STATUS,
  DEFAULT_SORT,
  SORT_OPTIONS,
} from '~/admin/abuse_reports/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

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

  const createComponent = () => {
    wrapper = shallowMount(AbuseReportsFilteredSearchBar);
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  beforeEach(() => {
    setWindowLocation('https://localhost');
  });

  it('passes correct props to `FilteredSearchBar` component', () => {
    createComponent();

    expect(findFilteredSearchBar().props()).toMatchObject({
      namespace: 'abuse_reports',
      recentSearchesStorageKey: 'abuse_reports',
      searchInputPlaceholder: 'Filter reports',
      tokens: FILTERED_SEARCH_TOKENS,
      initialSortBy: DEFAULT_SORT,
      sortOptions: SORT_OPTIONS,
    });
  });

  it('sets status=open query when there is no initial status query', () => {
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
  });

  it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
    setWindowLocation('?status=closed&user=mr_abuser');

    createComponent();

    expect(findFilteredSearchBar().props('initialFilterValue')).toMatchObject([
      {
        type: FILTERED_SEARCH_TOKEN_USER.type,
        value: { data: 'mr_abuser', operator: '=' },
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

    const createComponentAndFilter = (filterTokens, initialLocation) => {
      if (initialLocation) {
        setWindowLocation(initialLocation);
      }

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);
    };

    it('redirects with user query param', () => {
      createComponentAndFilter([USER_FILTER_TOKEN]);
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser');
    });

    it('redirects with status query param', () => {
      const statusFilterToken = {
        type: FILTERED_SEARCH_TOKEN_STATUS.type,
        value: { data: 'open', operator: '=' },
      };
      createComponentAndFilter([statusFilterToken]);
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?status=open');
    });

    it('ignores search query param', () => {
      const searchFilterToken = { type: FILTERED_SEARCH_TERM, value: { data: 'ignored' } };
      createComponentAndFilter([USER_FILTER_TOKEN, searchFilterToken]);
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser');
    });

    it('redirects without page query param', () => {
      createComponentAndFilter([USER_FILTER_TOKEN], '?page=2');
      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser');
    });

    it('redirects with existing sort query param', () => {
      createComponentAndFilter([USER_FILTER_TOKEN], `?sort=${DEFAULT_SORT}`);
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

      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });

    it('redirects without page query param', () => {
      createComponentAndSort(`?${EXISTING_QUERY}&page=2`);

      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });

    it('redirects with existing sort query param replaced with the new one', () => {
      createComponentAndSort(`?${EXISTING_QUERY}&sort=created_at_desc`);

      expect(redirectTo).toHaveBeenCalledWith(
        `https://localhost/?${EXISTING_QUERY}&sort=${SORT_VALUE}`,
      );
    });
  });
});
