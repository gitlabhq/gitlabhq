import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { createRouter } from '~/explore/groups';
import { EXPLORE_GROUPS_TABS } from '~/explore/groups/constants';

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
        created_at: 'createdAt',
        updated_at: 'updatedAt',
      },
      initialSort: 'latest_activity',
      shouldUpdateActiveTabCountFromTabQuery: false,
    });
  });
});
