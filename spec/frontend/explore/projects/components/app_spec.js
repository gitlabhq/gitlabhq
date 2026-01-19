import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';
import ExploreProjectsApp from '~/explore/projects/components/app.vue';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { createRouter } from '~/explore/projects';
import createMockApollo from 'helpers/mock_apollo_helper';
import { programmingLanguages } from 'jest/groups_projects/components/mock_data';
import { EXPLORE_PROJECTS_TABS, TRENDING_TAB } from '~/explore/projects/constants';

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('ExploreProjectsApp', () => {
  let wrapper;
  let router;

  const defaultPropsData = {
    initialSort: 'latest_activity',
    programmingLanguages,
  };

  const defaultRoute = {
    name: 'root',
  };

  const createComponent = async ({
    handlers = [],
    route = defaultRoute,
    provide = {},
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo(handlers);
    router = createRouter('/explore/projects');
    await router.push(route);

    wrapper = shallowMount(ExploreProjectsApp, {
      propsData: defaultPropsData,
      apolloProvider,
      router,
      provide,
      stubs,
    });
  };

  const findTabsWithList = () => wrapper.findComponent(TabsWithList);

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

    expect(findTabsWithList().props()).toMatchObject({
      tabs: EXPLORE_PROJECTS_TABS,
      filteredSearchSupportedTokens: ['language', 'min_access_level'],
      filteredSearchTermKey: 'name',
      filteredSearchNamespace: 'explore',
      filteredSearchRecentSearchesStorageKey: 'projects',
      filteredSearchInputPlaceholder: 'Filter or search (3 character minimum)',
      timestampTypeMap: {
        created: 'createdAt',
        latest_activity: 'lastActivityAt',
      },
      initialSort: defaultPropsData.initialSort,
      programmingLanguages: defaultPropsData.programmingLanguages,
      userPreferencesSortKey: 'projectsSort',
    });
  });

  describe('when retireTrendingProjects feature is enabled', () => {
    it('does not include trending tab', async () => {
      await createComponent({
        provide: { glFeatures: { retireTrendingProjects: true } },
      });

      expect(findTabsWithList().props('tabs')).not.toContainEqual(TRENDING_TAB);
    });
  });

  describe('when retireTrendingProjects feature is disabled', () => {
    it('includes trending tab', async () => {
      await createComponent({
        provide: { glFeatures: { retireTrendingProjects: false } },
      });

      expect(findTabsWithList().props('tabs')).toContainEqual(TRENDING_TAB);
    });
  });
});
