import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { SEARCH_TYPE_ZOEKT, SEARCH_TYPE_ADVANCED } from '~/search/sidebar/constants';
import { MOCK_QUERY } from 'jest/search/mock_data';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import ProjectsFilters from '~/search/sidebar/components/projects_filters.vue';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import SmallScreenDrawerNavigation from '~/search/sidebar/components/small_screen_drawer_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager');

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
  const findSmallScreenDrawerNavigation = () => wrapper.findComponent(SmallScreenDrawerNavigation);
  const findScopeSidebarNavigation = () => wrapper.findComponent(ScopeSidebarNavigation);
  const findDomElementListener = () => wrapper.findComponent(DomElementListener);

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
        createComponent({ urlQuery: { scope }, searchType: SEARCH_TYPE_ADVANCED });
      });

      it(`shows filter ${filter.name.replace('find', '')}`, () => {
        expect(filter().exists()).toBe(true);
      });
    });

    describe('filters for blobs will not load if zoekt is enabled', () => {
      beforeEach(() => {
        createComponent({ urlQuery: { scope: 'blobs' }, searchType: SEARCH_TYPE_ZOEKT });
      });

      it("doesn't render blobs filters", () => {
        expect(findBlobsFilters().exists()).toBe(false);
      });
    });

    describe('with sidebar scope: projects', () => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => 'projects');
        createComponent({ urlQuery: { scope: 'projects' } });
      });

      it(`shows filter ProjectsFilters`, () => {
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
        expect(findSmallScreenDrawerNavigation().exists()).toBe(legacyNavShown);
      });

      it(`${!sidebarNavShown ? 'hides' : 'shows'} the sidebar navigation`, () => {
        expect(findScopeSidebarNavigation().exists()).toBe(sidebarNavShown);
      });
    });
  });

  describe('when useSidebarNavigation=true', () => {
    beforeEach(() => {
      createComponent({ useSidebarNavigation: true });
    });

    it('toggles super sidebar when button is clicked', () => {
      const elListener = findDomElementListener();

      expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();

      elListener.vm.$emit('click');

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledTimes(1);
      expect(elListener.props('selector')).toBe('#js-open-mobile-filters');
    });
  });
});
