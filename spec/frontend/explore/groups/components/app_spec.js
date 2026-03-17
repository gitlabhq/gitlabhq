import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { createRouter } from '~/explore/groups';
import { EXPLORE_GROUPS_TABS, FILTERED_SEARCH_TERM_KEY } from '~/explore/groups/constants';

Vue.use(VueRouter);

describe('ExploreGroupsApp', () => {
  let wrapper;
  let router;

  const defaultPropsData = {
    initialSort: 'latest_activity',
  };

  const createComponent = () => {
    router = createRouter('/explore/groups');

    wrapper = shallowMount(ExploreGroupsApp, {
      propsData: defaultPropsData,
      router,
    });
  };

  const findTabsWithList = () => wrapper.findComponent(TabsWithList);

  it('renders TabsWithList component and passes correct props', () => {
    createComponent();

    expect(findTabsWithList().props()).toMatchObject({
      tabs: EXPLORE_GROUPS_TABS,
      filteredSearchTermKey: 'search',
      filteredSearchNamespace: 'explore',
      filteredSearchRecentSearchesStorageKey: 'groups',
      filteredSearchInputPlaceholder: 'Search',
      timestampTypeMap: {
        created: 'createdAt',
        updated: 'updatedAt',
      },
      initialSort: 'latest_activity',
      eventTracking: {
        filteredSearch: {
          [FILTERED_SEARCH_TERM_KEY]: 'search_on_explore_groups',
        },
        pagination: 'click_pagination_on_explore_groups',
        tabs: 'click_tab_on_explore_groups',
        sort: 'click_sort_on_explore_groups',
        hoverStat: 'hover_stat_on_explore_groups',
        hoverVisibility: 'hover_visibility_icon_on_explore_groups',
        initialLoad: 'initial_load_on_explore_groups',
        clickItem: 'click_group_on_explore_groups',
        clickItemAfterFilter: 'click_group_after_filter_on_explore_groups',
      },
      shouldUpdateActiveTabCountFromTabQuery: false,
    });
  });
});
