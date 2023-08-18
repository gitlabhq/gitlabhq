import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter/index.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import LabelFilter from '~/search/sidebar/components/label_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearch IssuesFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'issues',
  };

  const createComponent = (initialState, ff = true) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      getters: defaultGetters,
    });

    wrapper = shallowMount(IssuesFilters, {
      store,
      provide: {
        glFeatures: {
          searchIssueLabelAggregation: ff,
        },
      },
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);
  const findLabelFilter = () => wrapper.findComponent(LabelFilter);
  const findDividers = () => wrapper.findAll('hr');

  describe('Renders correctly with FF enabled', () => {
    beforeEach(() => {
      createComponent({ urlQuery: MOCK_QUERY });
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

    it('renders dividers correctly', () => {
      expect(findDividers()).toHaveLength(2);
    });
  });

  describe('Renders correctly with FF disabled', () => {
    beforeEach(() => {
      createComponent({ urlQuery: MOCK_QUERY }, false);
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

    it('renders divider correctly', () => {
      expect(findDividers()).toHaveLength(1);
    });
  });

  describe('Renders correctly with wrong scope', () => {
    beforeEach(() => {
      defaultGetters.currentScope = () => 'blobs';
      createComponent({ urlQuery: MOCK_QUERY });
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

    it("doesn't render dividers", () => {
      expect(findDividers()).toHaveLength(0);
    });
  });
});
