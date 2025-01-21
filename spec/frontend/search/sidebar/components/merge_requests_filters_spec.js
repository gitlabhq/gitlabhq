import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import SourceBranchFilter from '~/search/sidebar/components/source_branch_filter/index.vue';
import LabelFilter from '~/search/sidebar/components/label_filter/index.vue';
import AuthorFilter from '~/search/sidebar/components/author_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearch MergeRequestsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'merge_requests',
    hasMissingProjectContext: () => true,
  };

  const createComponent = (
    initialState = {},
    provide = {
      glFeatures: {
        searchMrFilterSourceBranch: true,
      },
    },
  ) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        searchType: 'advanced',
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
  const findLabelFilter = () => wrapper.findComponent(LabelFilter);
  const findAuthorFilter = () => wrapper.findComponent(AuthorFilter);

  describe('When renders correctly with Archived Filter', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders SourceBranchFilter', () => {
      expect(findSourceBranchFilter().exists()).toBe(true);
    });

    it('renders LabelFilter', () => {
      expect(findLabelFilter().exists()).toBe(true);
    });

    it('renders AuthorFilter', () => {
      expect(findAuthorFilter().exists()).toBe(true);
    });
  });

  describe('When renders correctly with basic search', () => {
    beforeEach(() => {
      createComponent({ searchType: 'basic' });
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders SourceBranchFilter', () => {
      expect(findSourceBranchFilter().exists()).toBe(true);
    });

    it('will not render LabelFilter', () => {
      expect(findLabelFilter().exists()).toBe(false);
    });

    it('will not render AuthorFilter', () => {
      expect(findAuthorFilter().exists()).toBe(false);
    });
  });

  describe('When feature flag search_mr_filter_source_branch is disabled', () => {
    beforeEach(() => {
      createComponent(null, { glFeatures: { searchMrFilterSourceBranch: false } });
    });

    it(`will not render SourceBranchFilter`, () => {
      expect(findSourceBranchFilter().exists()).toBe(false);
    });
  });

  describe('#hasMissingProjectContext getter', () => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => false;
      createComponent();
    });

    it('hides ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });
  });
});
