import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import ProjectsFilters from '~/search/sidebar/components/projects_filters.vue';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'issues'),
  };

  const createComponent = (initialState = {}) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      getters: getterSpies,
    });

    wrapper = shallowMount(GlobalSearchSidebar, {
      store,
    });
  };

  const findSidebarSection = () => wrapper.find('section');
  const findIssuesFilters = () => wrapper.findComponent(IssuesFilters);
  const findMergeRequestsFilters = () => wrapper.findComponent(MergeRequestsFilters);
  const findBlobsFilters = () => wrapper.findComponent(BlobsFilters);
  const findProjectsFilters = () => wrapper.findComponent(ProjectsFilters);
  const findScopeLegacyNavigation = () => wrapper.findComponent(ScopeLegacyNavigation);
  const findScopeSidebarNavigation = () => wrapper.findComponent(ScopeSidebarNavigation);

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
      scope               | filter
      ${'issues'}         | ${findIssuesFilters}
      ${'merge_requests'} | ${findMergeRequestsFilters}
      ${'blobs'}          | ${findBlobsFilters}
    `('with sidebar $scope scope:', ({ scope, filter }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({ urlQuery: { scope } });
      });

      it(`shows filter ${filter.name.replace('find', '')}`, () => {
        expect(filter().exists()).toBe(true);
      });
    });

    describe('with sidebar $scope scope:', () => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => 'projects');
        createComponent({ urlQuery: { scope: 'projects' } });
      });

      it(`shows filter ProjectsFilters}`, () => {
        expect(findProjectsFilters().exists()).toBe(true);
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
