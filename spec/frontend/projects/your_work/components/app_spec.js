import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import { PROJECT_DASHBOARD_TABS, FIRST_TAB_ROUTE_NAMES } from '~/projects/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { programmingLanguages } from 'jest/groups_projects/components/mock_data';

describe('YourWorkProjectsApp', () => {
  let wrapper;

  const defaultPropsData = {
    initialSort: 'created_desc',
    programmingLanguages,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(YourWorkProjectsApp, { propsData: defaultPropsData });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders TabsWithList component and passes correct props', () => {
    expect(wrapper.findComponent(TabsWithList).props()).toEqual({
      tabs: PROJECT_DASHBOARD_TABS,
      filteredSearchSupportedTokens: [
        FILTERED_SEARCH_TOKEN_LANGUAGE,
        FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
      ],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
      sortOptions: SORT_OPTIONS,
      defaultSortOption: SORT_OPTION_UPDATED,
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
      },
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
      initialSort: defaultPropsData.initialSort,
      programmingLanguages: defaultPropsData.programmingLanguages,
      eventTracking: {
        filteredSearch: {
          [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_projects',
          [FILTERED_SEARCH_TOKEN_LANGUAGE]: 'filter_by_language_on_your_work_projects',
          [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: 'filter_by_role_on_your_work_projects',
        },
        pagination: 'click_pagination_on_your_work_projects',
        tabs: 'click_tab_on_your_work_projects',
        sort: 'click_sort_on_your_work_projects',
      },
    });
  });
});
