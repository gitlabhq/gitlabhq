import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import SourceBranchFilter from '~/search/sidebar/components/source_branch_filter/index.vue';
import { SEARCH_TYPE_ADVANCED, SEARCH_TYPE_BASIC } from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('GlobalSearch MergeRequestsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'merge_requests',
    hasMissingProjectContext: () => true,
  };

  const createComponent = (
    initialState = {},
    provide = { glFeatures: { searchMrFilterSourceBranch: true } },
  ) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        searchType: SEARCH_TYPE_ADVANCED,
        groupInitialJson: {
          id: 1,
        },
        ...initialState,
      },
      getters: defaultGetters,
    });

    wrapper = shallowMount(MergeRequestsFilters, {
      store,
      provide,
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findSourceBranchFilter = () => wrapper.findComponent(SourceBranchFilter);

  describe('Renders correctly with Archived Filter', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders sourceBranchFilter', () => {
      expect(findSourceBranchFilter().exists()).toBe(true);
    });
  });

  describe('Renders correctly with basic search', () => {
    beforeEach(() => {
      createComponent({ searchType: SEARCH_TYPE_BASIC });
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders sourceBranchFilter', () => {
      expect(findSourceBranchFilter().exists()).toBe(true);
    });
  });

  describe.each([true, false])(
    'When feature flag search_mr_filter_source_branch is',
    (searchMrFilterSourceBranch) => {
      beforeEach(() => {
        createComponent(null, { glFeatures: { searchMrFilterSourceBranch } });
      });

      it('renders StatusFilter', () => {
        expect(findStatusFilter().exists()).toBe(true);
      });

      it('renders ArchivedFilter', () => {
        expect(findArchivedFilter().exists()).toBe(true);
      });

      it('renders sourceBranchFilter', () => {
        expect(findSourceBranchFilter().exists()).toBe(searchMrFilterSourceBranch);
      });
    },
  );

  describe('hasMissingProjectContext getter', () => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => false;
      createComponent();
    });

    it('hides archived filter', () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });
  });
});
