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
import TypeFilter from '~/search/sidebar/components/type_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearch IssuesFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'issues',
    hasMissingProjectContext: () => true,
    workItemTypes: () => [],
  };

  const createComponent = ({ initialState = {}, getters = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        searchType: 'advanced',
        ...initialState,
      },
      getters: { ...defaultGetters, ...getters },
    });

    wrapper = shallowMount(IssuesFilters, {
      store,
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);
  const findLabelFilter = () => wrapper.findComponent(LabelFilter);
  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findTypeFilter = () => wrapper.findComponent(TypeFilter);

  describe('Renders filters correctly with advanced search', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it('renders correctly ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders correctly LabelFilter', () => {
      expect(findLabelFilter().exists()).toBe(true);
    });
  });

  describe('Renders correctly with basic search', () => {
    beforeEach(() => {
      createComponent({ initialState: { searchType: 'basic' } });
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

    it('does render ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });
  });

  describe('hasMissingProjectContext getter', () => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => false;
      createComponent();
    });

    it('hides archived filter', () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });
  });

  describe('TypeFilter', () => {
    describe('when scope is work_items and workItemTypes has items', () => {
      beforeEach(() => {
        createComponent({
          getters: {
            currentScope: () => 'work_items',
            workItemTypes: () => [
              { name: 'issue', label: 'Issue' },
              { name: 'task', label: 'Task' },
            ],
          },
        });
      });

      it('renders TypeFilter', () => {
        expect(findTypeFilter().exists()).toBe(true);
      });
    });

    describe('when scope is work_items but workItemTypes is empty (global search)', () => {
      beforeEach(() => {
        createComponent({
          getters: {
            currentScope: () => 'work_items',
            workItemTypes: () => [],
          },
        });
      });

      it('does not render TypeFilter', () => {
        expect(findTypeFilter().exists()).toBe(false);
      });
    });

    describe('when scope is not work_items', () => {
      beforeEach(() => {
        createComponent({
          getters: {
            currentScope: () => 'issues',
            workItemTypes: () => [
              { name: 'issue', label: 'Issue' },
              { name: 'task', label: 'Task' },
            ],
          },
        });
      });

      it('does not render TypeFilter', () => {
        expect(findTypeFilter().exists()).toBe(false);
      });
    });
  });
});
