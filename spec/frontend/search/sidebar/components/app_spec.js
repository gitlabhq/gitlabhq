import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'issues'),
  };

  const createComponent = (initialState = {}, featureFlags = {}) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      getters: getterSpies,
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

  const findSidebarSection = () => wrapper.find('section');
  const findFilters = () => wrapper.findComponent(IssuesFilters);
  const findScopeLegacyNavigation = () => wrapper.findComponent(ScopeLegacyNavigation);
  const findScopeSidebarNavigation = () => wrapper.findComponent(ScopeSidebarNavigation);
  const findLanguageAggregation = () => wrapper.findComponent(LanguageFilter);

  describe('renders properly', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });
      it(`shows section`, () => {
        expect(findSidebarSection().exists()).toBe(true);
      });
    });

    describe.each`
      scope               | showFilters | showsLanguage
      ${'issues'}         | ${true}     | ${false}
      ${'merge_requests'} | ${true}     | ${false}
      ${'projects'}       | ${false}    | ${false}
      ${'blobs'}          | ${false}    | ${true}
    `('sidebar scope: $scope', ({ scope, showFilters, showsLanguage }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({ urlQuery: { scope } });
      });

      it(`${!showFilters ? "doesn't" : ''} shows filters`, () => {
        expect(findFilters().exists()).toBe(showFilters);
      });

      it(`${!showsLanguage ? "doesn't" : ''} shows language filters`, () => {
        expect(findLanguageAggregation().exists()).toBe(showsLanguage);
      });
    });

    describe.each`
      currentScope | sidebarNavShown | legacyNavShown
      ${'issues'}  | ${false}        | ${true}
      ${''}        | ${false}        | ${false}
      ${'issues'}  | ${true}         | ${false}
      ${''}        | ${true}         | ${false}
    `('renders navigation', ({ currentScope, sidebarNavShown, legacyNavShown }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => currentScope);
        createComponent({ useSidebarNavigation: sidebarNavShown });
      });

      it(`${!legacyNavShown ? 'hides' : 'shows'} the legacy navigation`, () => {
        expect(findScopeLegacyNavigation().exists()).toBe(legacyNavShown);
      });

      it(`${!sidebarNavShown ? 'hides' : 'shows'} the sidebar navigation`, () => {
        expect(findScopeSidebarNavigation().exists()).toBe(sidebarNavShown);
      });
    });
  });
});
