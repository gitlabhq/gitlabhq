import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import IssuesFilters from '~/search/sidebar/components/issues_filters.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter/index.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebarFilters', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const defaultGetters = {
    currentScope: () => 'issues',
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: defaultGetters,
    });

    wrapper = shallowMount(IssuesFilters, {
      store,
    });
  };

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent({ urlQuery: MOCK_QUERY });
    });
    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });
  });

  describe.each`
    scope               | showFilter
    ${'issues'}         | ${true}
    ${'merge_requests'} | ${false}
    ${'projects'}       | ${false}
    ${'milestones'}     | ${false}
    ${'users'}          | ${false}
    ${'notes'}          | ${false}
    ${'wiki_blobs'}     | ${false}
    ${'blobs'}          | ${false}
  `(`ConfidentialityFilter`, ({ scope, showFilter }) => {
    beforeEach(() => {
      defaultGetters.currentScope = () => scope;
      createComponent();
    });
    afterEach(() => {
      defaultGetters.currentScope = () => 'issues';
    });

    it(`does${showFilter ? '' : ' not'} render when scope is ${scope}`, () => {
      expect(findConfidentialityFilter().exists()).toBe(showFilter);
    });
  });

  describe.each`
    scope               | showFilter
    ${'issues'}         | ${true}
    ${'merge_requests'} | ${true}
    ${'projects'}       | ${false}
    ${'milestones'}     | ${false}
    ${'users'}          | ${false}
    ${'notes'}          | ${false}
    ${'wiki_blobs'}     | ${false}
    ${'blobs'}          | ${false}
  `(`StatusFilter`, ({ scope, showFilter }) => {
    beforeEach(() => {
      defaultGetters.currentScope = () => scope;
      createComponent();
    });
    afterEach(() => {
      defaultGetters.currentScope = () => 'issues';
    });

    it(`does${showFilter ? '' : ' not'} render when scope is ${scope}`, () => {
      expect(findStatusFilter().exists()).toBe(showFilter);
    });
  });
});
