import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import { SEARCH_TYPE_ADVANCED, SEARCH_TYPE_BASIC } from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('GlobalSearch MergeRequestsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'merge_requests',
  };

  const createComponent = ({
    initialState = {},
    searchMergeRequestsHideArchivedProjects = true,
  } = {}) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        useSidebarNavigation: false,
        searchType: SEARCH_TYPE_ADVANCED,
        ...initialState,
      },
      getters: defaultGetters,
    });

    wrapper = shallowMount(MergeRequestsFilters, {
      store,
      provide: {
        glFeatures: {
          searchMergeRequestsHideArchivedProjects,
        },
      },
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findDividers = () => wrapper.findAll('hr');

  describe.each`
    description                                          | searchMergeRequestsHideArchivedProjects
    ${'Renders correctly with Archived Filter disabled'} | ${false}
    ${'Renders correctly with Archived Filter enabled'}  | ${true}
  `('$description', ({ searchMergeRequestsHideArchivedProjects }) => {
    beforeEach(() => {
      createComponent({
        searchMergeRequestsHideArchivedProjects,
      });
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it(`renders correctly ArchivedFilter when searchMergeRequestsHideArchivedProjects is ${searchMergeRequestsHideArchivedProjects}`, () => {
      expect(findArchivedFilter().exists()).toBe(searchMergeRequestsHideArchivedProjects);
    });

    it('renders divider correctly', () => {
      const dividersCount = searchMergeRequestsHideArchivedProjects ? 1 : 0;
      expect(findDividers()).toHaveLength(dividersCount);
    });
  });

  describe('Renders correctly with basic search', () => {
    beforeEach(() => {
      createComponent({ initialState: { searchType: SEARCH_TYPE_BASIC } });
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it("doesn't render ArchivedFilter", () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });

    it('renders 1 divider', () => {
      expect(findDividers()).toHaveLength(0);
    });
  });

  describe('Renders correctly in new nav', () => {
    beforeEach(() => {
      createComponent({
        initialState: {
          searchType: SEARCH_TYPE_ADVANCED,
          useSidebarNavigation: true,
        },
        searchMergeRequestsHideArchivedProjects: true,
      });
    });
    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it("doesn't render divider", () => {
      expect(findDividers()).toHaveLength(0);
    });
  });

  describe('Renders correctly with wrong scope', () => {
    beforeEach(() => {
      defaultGetters.currentScope = () => 'blobs';
      createComponent();
    });
    it("doesn't render StatusFilter", () => {
      expect(findStatusFilter().exists()).toBe(false);
    });

    it("doesn't render ArchivedFilter", () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });

    it("doesn't render dividers", () => {
      expect(findDividers()).toHaveLength(0);
    });
  });
});
