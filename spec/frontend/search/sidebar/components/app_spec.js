import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import ResultsFilters from '~/search/sidebar/components/results_filters.vue';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const createComponent = (initialState, featureFlags) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchSidebar, {
      store,
      provide: {
        glFeatures: {
          ...featureFlags,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSidebarSection = () => wrapper.find('section');
  const findFilters = () => wrapper.findComponent(ResultsFilters);
  const findSidebarNavigation = () => wrapper.findComponent(ScopeNavigation);

  describe('renders properly', () => {
    describe('scope=projects', () => {
      beforeEach(() => {
        createComponent({ urlQuery: { ...MOCK_QUERY, scope: 'projects' } });
      });

      it('shows section', () => {
        expect(findSidebarSection().exists()).toBe(true);
      });

      it("doesn't shows filters", () => {
        expect(findFilters().exists()).toBe(false);
      });
    });

    describe('scope=merge_requests', () => {
      beforeEach(() => {
        createComponent({ urlQuery: { ...MOCK_QUERY, scope: 'merge_requests' } });
      });

      it('shows section', () => {
        expect(findSidebarSection().exists()).toBe(true);
      });

      it('shows filters', () => {
        expect(findFilters().exists()).toBe(true);
      });
    });

    describe('scope=issues', () => {
      beforeEach(() => {
        createComponent({ urlQuery: MOCK_QUERY });
      });
      it('shows section', () => {
        expect(findSidebarSection().exists()).toBe(true);
      });

      it('shows filters', () => {
        expect(findFilters().exists()).toBe(true);
      });
    });

    describe('renders navigation', () => {
      beforeEach(() => {
        createComponent({});
      });
      it('shows the vertical navigation', () => {
        expect(findSidebarNavigation().exists()).toBe(true);
      });
    });
  });
});
