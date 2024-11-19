import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import AdminGroupsFilteredSearchAndSort from '~/admin/groups/components/filtered_search_and_sort.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import {
  FILTERED_SEARCH_TERM_KEY,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_CREATED_DATE,
  SORT_OPTION_UPDATED_DATE,
  SORT_OPTIONS,
} from '~/admin/groups/constants';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('AdminGroupsFilteredSearchAndSort', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminGroupsFilteredSearchAndSort, {});
  };

  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);

  it('renders FilteredSearchAndSort component with the correct initial props', () => {
    createComponent();

    expect(findFilteredSearchAndSort().props()).toMatchObject({
      filteredSearchNamespace: 'admin-groups',
      filteredSearchTokens: [],
      filteredSearchTermKey: 'name',
      filteredSearchRecentSearchesStorageKey: 'groups',
      isAscending: false,
      sortOptions: SORT_OPTIONS,
      activeSortOption: SORT_OPTION_CREATED_DATE,
      filteredSearchQuery: {},
    });
  });

  describe('when the search bar is submitted', () => {
    const searchTerm = 'test';

    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [FILTERED_SEARCH_TERM_KEY]: searchTerm,
      });
    });

    it('visits the URL with the correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(`?${FILTERED_SEARCH_TERM_KEY}=${searchTerm}`);
    });
  });

  describe('when the sort item is changed', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_OPTION_UPDATED_DATE.value);
    });

    it('visits the URL with the correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?sort=${SORT_OPTION_UPDATED_DATE.value}_${SORT_DIRECTION_DESC}`,
      );
    });
  });

  describe('when the sort direction is changed', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', true);
    });

    it('visits the URL with the correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?sort=${SORT_OPTION_CREATED_DATE.value}_${SORT_DIRECTION_ASC}`,
      );
    });
  });

  describe('when the search term is present and the sort item is changed', () => {
    const searchTerm = 'group-name';

    beforeEach(() => {
      setWindowLocation(`?${FILTERED_SEARCH_TERM_KEY}=${searchTerm}`);

      createComponent();

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', true);
    });

    it('visits the URL with the correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?${FILTERED_SEARCH_TERM_KEY}=${searchTerm}&sort=${SORT_OPTION_CREATED_DATE.value}_${SORT_DIRECTION_ASC}`,
      );
    });
  });

  describe('when the sort item is present and the search term is changed', () => {
    const searchTerm = 'group-name';

    beforeEach(() => {
      setWindowLocation(`?sort=${SORT_OPTION_CREATED_DATE.value}_${SORT_DIRECTION_ASC}`);

      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [FILTERED_SEARCH_TERM_KEY]: searchTerm,
      });
    });

    it('visits the URL with the correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?${FILTERED_SEARCH_TERM_KEY}=${searchTerm}&sort=${SORT_OPTION_CREATED_DATE.value}_${SORT_DIRECTION_ASC}`,
      );
    });
  });
});
