import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
import AllScopesStartFilters from '~/search/sidebar/components/all_scopes_start_filters.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';

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

    wrapper = shallowMountExtended(GlobalSearchSidebar, {
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
  const findAllScopesStartFilters = () => wrapper.findComponent(AllScopesStartFilters);
  const findSidebarPortal = () => wrapper.findComponent(SidebarPortal);
  const findFiltersContainer = () => wrapper.findByTestId('search-filters');

  beforeEach(() => {
    delete window.gon;
  });

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
      ${'issues'}         | ${findAllScopesStartFilters}
      ${'merge_requests'} | ${findMergeRequestsFilters}
      ${'merge_requests'} | ${findAllScopesStartFilters}
      ${'projects'}       | ${findProjectsFilters}
      ${'projects'}       | ${findAllScopesStartFilters}
      ${'blobs'}          | ${findAllScopesStartFilters}
      ${'notes'}          | ${findNotesFilters}
      ${'notes'}          | ${findAllScopesStartFilters}
      ${'commits'}        | ${findCommitsFilters}
      ${'commits'}        | ${findAllScopesStartFilters}
      ${'milestones'}     | ${findMilestonesFilters}
      ${'milestones'}     | ${findAllScopesStartFilters}
      ${'wiki_blobs'}     | ${findWikiBlobsFilters}
      ${'wiki_blobs'}     | ${findAllScopesStartFilters}
    `('with sidebar scope: $scope', ({ scope, filter }) => {
      describe.each(['basic', 'advanced'])('with search_type %s', (searchType) => {
        beforeEach(() => {
          getterSpies.currentScope = jest.fn(() => scope);
          createComponent({ urlQuery: { scope }, searchType });
        });

        it(`renders correctly ${filter.name.replace('find', '')}`, () => {
          expect(filter().exists()).toBe(true);
        });
      });
    });

    describe.each`
      scope      | searchType    | isShown
      ${'blobs'} | ${'basic'}    | ${false}
      ${'blobs'} | ${'advanced'} | ${true}
      ${'blobs'} | ${'zoekt'}    | ${true}
    `('sidebar blobs scope:', ({ scope, searchType, isShown }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({
          urlQuery: { scope },
          searchType,
        });
      });

      it(`does ${
        isShown ? '' : 'not '
      }render filter BlobsFilters when search_type ${searchType}`, () => {
        expect(findBlobsFilters().exists()).toBe(isShown);
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

  describe('Project Studio mode', () => {
    beforeEach(() => {
      window.gon = { features: { projectStudioEnabled: true } };
    });

    describe('filters', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders filters container', () => {
        expect(findFiltersContainer().exists()).toBe(true);
      });

      it('does not render sidebar portal', () => {
        expect(findSidebarPortal().exists()).toBe(false);
      });
    });

    describe('toggleFilters method', () => {
      it('toggles gl-hidden class on filters container', () => {
        createComponent();
        const elListener = findDomElementListener();

        expect(findFiltersContainer().classes()).toContain('gl-hidden');
        elListener.vm.$emit('click');
        expect(findFiltersContainer().classes()).not.toContain('gl-hidden');
        elListener.vm.$emit('click');
        expect(findFiltersContainer().classes()).toContain('gl-hidden');

        expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();
      });
    });
  });

  describe('Legacy mode (Project Studio disabled)', () => {
    beforeEach(() => {
      window.gon = { features: { projectStudioEnabled: false } };
    });

    describe('sidebar portal', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders sidebar portal when Project Studio is disabled', () => {
        expect(findSidebarPortal().exists()).toBe(true);
      });

      it('does not render mobile filters container when Project Studio is disabled', () => {
        expect(findFiltersContainer().exists()).toBe(false);
      });
    });
  });
});
