import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter/index.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import LabelFilter from '~/search/sidebar/components/label_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import { SEARCH_TYPE_ADVANCED, SEARCH_TYPE_BASIC } from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('GlobalSearch IssuesFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'issues',
  };

  const createComponent = ({
    initialState = {},
    searchIssueLabelAggregation = true,
    searchIssuesHideArchivedProjects = true,
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

    wrapper = shallowMount(IssuesFilters, {
      store,
      provide: {
        glFeatures: {
          searchIssueLabelAggregation,
          searchIssuesHideArchivedProjects,
        },
      },
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);
  const findLabelFilter = () => wrapper.findComponent(LabelFilter);
  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findDividers = () => wrapper.findAll('hr');

  describe.each`
    description                                                           | searchIssueLabelAggregation | searchIssuesHideArchivedProjects
    ${'Renders correctly with Label Filter disabled'}                     | ${false}                    | ${true}
    ${'Renders correctly with Archived Filter disabled'}                  | ${true}                     | ${false}
    ${'Renders correctly with Archived Filter and Label Filter disabled'} | ${false}                    | ${false}
    ${'Renders correctly with Archived Filter and Label Filter enabled'}  | ${true}                     | ${true}
  `('$description', ({ searchIssueLabelAggregation, searchIssuesHideArchivedProjects }) => {
    beforeEach(() => {
      createComponent({
        searchIssueLabelAggregation,
        searchIssuesHideArchivedProjects,
      });
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it(`renders correctly LabelFilter when searchIssueLabelAggregation is ${searchIssueLabelAggregation}`, () => {
      expect(findLabelFilter().exists()).toBe(searchIssueLabelAggregation);
    });

    it(`renders correctly ArchivedFilter when searchIssuesHideArchivedProjects is ${searchIssuesHideArchivedProjects}`, () => {
      expect(findArchivedFilter().exists()).toBe(searchIssuesHideArchivedProjects);
    });

    it('renders divider correctly', () => {
      // one divider can't be disabled
      let dividersCount = 1;
      if (searchIssueLabelAggregation) {
        dividersCount += 1;
      }
      if (searchIssuesHideArchivedProjects) {
        dividersCount += 1;
      }
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

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it("doesn't render LabelFilter", () => {
      expect(findLabelFilter().exists()).toBe(false);
    });

    it("doesn't render ArchivedFilter", () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });

    it('renders 1 divider', () => {
      expect(findDividers()).toHaveLength(1);
    });
  });

  describe('Renders correctly in new nav', () => {
    beforeEach(() => {
      createComponent({
        initialState: {
          searchType: SEARCH_TYPE_ADVANCED,
          useSidebarNavigation: true,
        },
        searchIssueLabelAggregation: true,
        searchIssuesHideArchivedProjects: true,
      });
    });
    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it('renders LabelFilter', () => {
      expect(findLabelFilter().exists()).toBe(true);
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it("doesn't render dividers", () => {
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

    it("doesn't render ConfidentialityFilter", () => {
      expect(findConfidentialityFilter().exists()).toBe(false);
    });

    it("doesn't render LabelFilter", () => {
      expect(findLabelFilter().exists()).toBe(false);
    });

    it("doesn't render ArchivedFilter", () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });

    it("doesn't render dividers", () => {
      expect(findDividers()).toHaveLength(0);
    });
  });
});
