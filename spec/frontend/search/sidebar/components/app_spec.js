import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import {
  SEARCH_TYPE_ZOEKT,
  SEARCH_TYPE_ADVANCED,
  SEARCH_TYPE_BASIC,
} from '~/search/sidebar/constants';
import { MOCK_QUERY } from 'jest/search/mock_data';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import ProjectsFilters from '~/search/sidebar/components/projects_filters.vue';
import NotesFilters from '~/search/sidebar/components/notes_filters.vue';
import CommitsFilters from '~/search/sidebar/components/commits_filters.vue';
import MilestonesFilters from '~/search/sidebar/components/milestones_filters.vue';
import WikiBlobsFilters from '~/search/sidebar/components/wiki_blobs_filters.vue';
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
  const findNotesFilters = () => wrapper.findComponent(NotesFilters);
  const findCommitsFilters = () => wrapper.findComponent(CommitsFilters);
  const findMilestonesFilters = () => wrapper.findComponent(MilestonesFilters);
  const findWikiBlobsFilters = () => wrapper.findComponent(WikiBlobsFilters);
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
      scope               | filter                      | searchType              | isShown
      ${'issues'}         | ${findIssuesFilters}        | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'merge_requests'} | ${findMergeRequestsFilters} | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'projects'}       | ${findProjectsFilters}      | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'blobs'}          | ${findBlobsFilters}         | ${SEARCH_TYPE_BASIC}    | ${false}
      ${'blobs'}          | ${findBlobsFilters}         | ${SEARCH_TYPE_ADVANCED} | ${true}
      ${'blobs'}          | ${findBlobsFilters}         | ${SEARCH_TYPE_ZOEKT}    | ${false}
      ${'notes'}          | ${findNotesFilters}         | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'notes'}          | ${findNotesFilters}         | ${SEARCH_TYPE_ADVANCED} | ${true}
      ${'commits'}        | ${findCommitsFilters}       | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'commits'}        | ${findCommitsFilters}       | ${SEARCH_TYPE_ADVANCED} | ${true}
      ${'milestones'}     | ${findMilestonesFilters}    | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'milestones'}     | ${findMilestonesFilters}    | ${SEARCH_TYPE_ADVANCED} | ${true}
      ${'wiki_blobs'}     | ${findWikiBlobsFilters}     | ${SEARCH_TYPE_BASIC}    | ${true}
      ${'wiki_blobs'}     | ${findWikiBlobsFilters}     | ${SEARCH_TYPE_ADVANCED} | ${true}
    `('with sidebar $scope scope:', ({ scope, filter, searchType, isShown }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({ urlQuery: { scope }, searchType });
      });

      it(`renders correctly filter ${filter.name.replace(
        'find',
        '',
      )} when search_type ${searchType}`, () => {
        expect(filter().exists()).toBe(isShown);
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

    describe.each(['issues', 'test'])('for scope %p', (currentScope) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => currentScope);
        createComponent();
      });

      it(`renders navigation correctly`, () => {
        expect(findScopeSidebarNavigation().exists()).toBe(true);
      });
    });
  });

  it('toggles super sidebar when button is clicked', () => {
    createComponent();
    const elListener = findDomElementListener();

    expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();

    elListener.vm.$emit('click');

    expect(toggleSuperSidebarCollapsed).toHaveBeenCalledTimes(1);
    expect(elListener.props('selector')).toBe('#js-open-mobile-filters');
  });
});
