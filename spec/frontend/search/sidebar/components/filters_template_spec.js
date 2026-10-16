import { GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_AGGREGATIONS, MOCK_NAVIGATION } from 'jest/search/mock_data';

import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';
import createStore from '~/search/store';
import { hasAppliedFilters, isZoektCodeSearch, sidebarFilterParams } from '~/search/store/getters';

import {
  TRACKING_ACTION_CLICK,
  TRACKING_LABEL_APPLY,
  TRACKING_LABEL_RESET,
} from '~/search/sidebar/constants/index';

Vue.use(Vuex);

describe('GlobalSearchSidebarLanguageFilter', () => {
  let wrapper;
  let trackingSpy;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const getterSpies = {
    currentScope: jest.fn(() => 'issues'),
    hasMissingProjectContext: jest.fn(() => true),
    workItemTypes: jest.fn(() => [{ name: 'issue', label: 'Issue' }]),
  };

  const unfilteredQuery = { scope: 'issues', search: '*', group_id: 1 };

  const createComponent = (initialState = {}, provide = {}) => {
    const store = new Vuex.Store({
      state: {
        query: unfilteredQuery,
        urlQuery: unfilteredQuery,
        aggregations: MOCK_AGGREGATIONS,
        groupInitialJson: { id: 1 },
        ...initialState,
      },
      actions: actionSpies,
      getters: { ...getterSpies, isZoektCodeSearch, sidebarFilterParams, hasAppliedFilters },
    });

    wrapper = shallowMountExtended(FiltersTemplate, {
      store,
      slots: {
        default: '<p>Filters Content</p>',
      },
      provide,
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findApplyButton = () => wrapper.findComponentByTestId('search-apply-filters-btn');
  const findResetButton = () => wrapper.findComponentByTestId('search-reset-filters-btn');
  const findSlotContent = () => wrapper.findByText('Filters Content');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('renders slot content', () => {
      expect(findSlotContent().exists()).toBe(true);
    });

    it('renders ApplyButton', () => {
      expect(findApplyButton().exists()).toBe(true);
    });

    it('does not render the reset button', () => {
      expect(findResetButton().exists()).toBe(false);
    });
  });

  describe('Reset filters button', () => {
    describe.each`
      scope               | searchType    | filter
      ${'issues'}         | ${'basic'}    | ${{ state: 'opened' }}
      ${'work_items'}     | ${'advanced'} | ${{ type: ['issue'] }}
      ${'merge_requests'} | ${'advanced'} | ${{ target_branch: 'main' }}
      ${'blobs'}          | ${'advanced'} | ${{ language: ['Ruby'] }}
      ${'projects'}       | ${'basic'}    | ${{ include_archived: 'true' }}
      ${'groups'}         | ${'advanced'} | ${{ include_archived: 'true' }}
      ${'notes'}          | ${'basic'}    | ${{ include_archived: 'true' }}
      ${'commits'}        | ${'basic'}    | ${{ include_archived: 'true' }}
      ${'milestones'}     | ${'basic'}    | ${{ include_archived: 'true' }}
      ${'wiki_blobs'}     | ${'basic'}    | ${{ include_archived: 'true' }}
    `('in the $scope scope with $searchType search', ({ scope, searchType, filter }) => {
      const scopeQuery = { ...unfilteredQuery, scope };
      const filteredQuery = { ...scopeQuery, ...filter };

      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
      });

      it('is hidden when no filters are applied', () => {
        createComponent({ searchType, query: scopeQuery, urlQuery: scopeQuery });

        expect(findResetButton().exists()).toBe(false);
      });

      it('is hidden when a filter is selected but not applied', () => {
        createComponent({ searchType, query: filteredQuery, urlQuery: scopeQuery });

        expect(findResetButton().exists()).toBe(false);
      });

      it('is shown when a filter is applied', () => {
        createComponent({ searchType, query: filteredQuery, urlQuery: filteredQuery });

        expect(findResetButton().exists()).toBe(true);
      });

      it('stays shown when an applied filter is cleared but not applied', () => {
        createComponent({ searchType, query: scopeQuery, urlQuery: filteredQuery });

        expect(findResetButton().exists()).toBe(true);
      });
    });

    it.each`
      scope         | searchType | filter
      ${'projects'} | ${'basic'} | ${{ state: 'opened' }}
      ${'issues'}   | ${'basic'} | ${{ label_name: ['bug'] }}
    `(
      'is hidden in the $scope scope with $searchType search when only $filter is applied, which that scope does not show',
      ({ scope, searchType, filter }) => {
        const filteredQuery = { ...unfilteredQuery, scope, ...filter };
        getterSpies.currentScope = jest.fn(() => scope);

        createComponent({ searchType, query: filteredQuery, urlQuery: filteredQuery });

        expect(findResetButton().exists()).toBe(false);
      },
    );

    it('is hidden on a later results page when the only filter change is not applied', () => {
      createComponent({
        query: { ...unfilteredQuery, page: 2, state: 'opened' },
        urlQuery: { ...unfilteredQuery, page: 2 },
      });

      expect(findResetButton().exists()).toBe(false);
    });

    describe('in the blobs scope with Zoekt search, which applies filters as they change', () => {
      const blobsQuery = { ...unfilteredQuery, scope: 'blobs' };

      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => 'blobs');
      });

      it.each([
        ['language', ['Ruby']],
        ['include_archived', 'true'],
        ['exclude_forks', 'true'],
      ])('is shown as soon as %s is selected', (param, value) => {
        createComponent({
          searchType: 'zoekt',
          query: { ...blobsQuery, [param]: value },
          urlQuery: blobsQuery,
        });

        expect(findResetButton().exists()).toBe(true);
      });

      it('is hidden as soon as the filters are cleared', () => {
        createComponent({
          searchType: 'zoekt',
          query: { ...blobsQuery, language: [] },
          urlQuery: { ...blobsQuery, language: ['Ruby'] },
        });

        expect(findResetButton().exists()).toBe(false);
      });
    });
  });

  describe('Reset filters button with the search store', () => {
    let store;

    const mountWithSearchStore = (query) => {
      store = createStore({ query, navigation: MOCK_NAVIGATION, searchType: 'basic' });
      wrapper = shallowMountExtended(FiltersTemplate, {
        store,
        slots: { default: '<p>Filters Content</p>' },
      });
    };

    it('is shown when the page loads with a filter applied', () => {
      mountWithSearchStore({ ...unfilteredQuery, state: 'opened' });

      expect(findResetButton().exists()).toBe(true);
    });

    it('stays hidden after a filter is selected but not applied', async () => {
      mountWithSearchStore({ ...unfilteredQuery, page: 2 });

      await store.dispatch('setQuery', { key: 'state', value: 'opened' });
      await nextTick();

      expect(findResetButton().exists()).toBe(false);
    });
  });

  describe('ApplyButton', () => {
    it('enables the button', () => {
      createComponent();

      expect(findApplyButton().attributes().disabled).toBeUndefined();
    });

    describe('when not zoekt multimatch', () => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => 'issues');

        createComponent({
          query: { scope: 'issues' },
          searchType: 'advanced_search',
        });
      });

      it('shows the button', () => {
        expect(findApplyButton().exists()).toBe(true);
      });
    });

    describe('when zoekt multimatch', () => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => 'blobs');
        getterSpies.hasMissingProjectContext = jest.fn(() => true);

        createComponent({
          query: { scope: 'blobs' },
          searchType: 'zoekt',
        });
      });

      it('shows the button', () => {
        expect(findApplyButton().exists()).toBe(false);
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      getterSpies.currentScope = jest.fn(() => 'issues');
      const filteredQuery = { ...unfilteredQuery, state: 'opened' };
      createComponent({ query: filteredQuery, urlQuery: filteredQuery });
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('clicking ApplyButton calls applyQuery', () => {
      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(actionSpies.applyQuery).toHaveBeenCalled();
      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_CLICK, TRACKING_LABEL_APPLY, {
        label: getterSpies.currentScope(),
      });
    });

    it('clicking resetButton calls resetQuery', () => {
      findResetButton().vm.$emit('click');

      expect(actionSpies.resetQuery).toHaveBeenCalled();
      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_CLICK, TRACKING_LABEL_RESET, {
        label: getterSpies.currentScope(),
      });
    });
  });
});
