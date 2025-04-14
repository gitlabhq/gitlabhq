import { GlLabel, GlCollapsibleListbox } from '@gitlab/ui';

import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_QUERY,
  MOCK_LABEL_AGGREGATIONS,
  MOCK_FILTERED_UNSELECTED_LABELS,
} from 'jest/search/mock_data';

import LabelFilter from '~/search/sidebar/components/label_filter/index.vue';

import * as actions from '~/search/store/actions';
import * as getters from '~/search/store/getters';
import mutations from '~/search/store/mutations';
import createState from '~/search/store/state';

import { RECEIVE_AGGREGATIONS_SUCCESS } from '~/search/store/mutation_types';

Vue.use(Vuex);

const actionSpies = {
  fetchAllAggregation: jest.fn(),
  setQuery: jest.fn(),
  closeLabel: jest.fn(),
  setLabelFilterSearch: jest.fn(),
};

describe('GlobalSearchSidebarLabelFilter', () => {
  let wrapper;
  let trackingSpy;
  let config;
  let store;
  let state;

  const createComponent = (initialState, gettersStubs) => {
    state = createState({
      query: MOCK_QUERY,
      aggregations: MOCK_LABEL_AGGREGATIONS,
      navigation: {},
      ...initialState,
    });

    config = {
      actions: {
        ...actions,
        fetchAllAggregation: actionSpies.fetchAllAggregation,
        closeLabel: actionSpies.closeLabel,
        setLabelFilterSearch: actionSpies.setLabelFilterSearch,
        setQuery: actionSpies.setQuery,
      },
      state,
      getters: {
        ...getters,
        ...gettersStubs,
      },
      mutations,
    };

    store = new Vuex.Store(config);

    wrapper = mountExtended(LabelFilter, {
      store,
      stubs: {
        DropdownKeyboardNavigation: true,
      },
    });
  };

  const findComponentTitle = () => wrapper.findByTestId('label-filter-title');
  const findAllSelectedLabelsAbove = () => wrapper.findAllComponents(GlLabel);
  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const findLabelPills = () => wrapper.findAllComponentsByTestId('label');
  const findSelectedUnappliedLabelPills = () =>
    wrapper.findAllComponentsByTestId('unapplied-label');
  const findClosedUnappliedPills = () => wrapper.findAllComponentsByTestId('unselected-label');

  describe('Renders correctly opened', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);

      await nextTick();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      await nextTick();
      findCollapsibleListbox().vm.open();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('renders component title', () => {
      expect(findComponentTitle().exists()).toBe(true);
    });

    it('renders selected labels above search box', () => {
      expect(findAllSelectedLabelsAbove().exists()).toBe(true);
      expect(findAllSelectedLabelsAbove()).toHaveLength(2);
    });

    it('sends tracking information when dropdown is opened', () => {
      expect(trackingSpy).toHaveBeenCalledWith('search:agreggations:label:show', 'Dropdown', {
        label: 'Dropdown',
      });
    });
  });

  describe('Renders correctly closed', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);

      await nextTick();
    });

    it('renders component title', () => {
      expect(findComponentTitle().exists()).toBe(true);
    });

    it('renders selected labels above search box', () => {
      expect(findAllSelectedLabelsAbove().exists()).toBe(true);
      expect(findAllSelectedLabelsAbove()).toHaveLength(2);
    });

    it('renders search dropdown', () => {
      expect(findCollapsibleListbox().exists()).toBe(true);
    });
  });

  describe('Actions', () => {
    describe('dispatch action when component is created', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders checkbox filter', async () => {
        await Vue.nextTick();
        expect(actionSpies.fetchAllAggregation).toHaveBeenCalled();
      });
    });

    describe('label search input box works properly', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders checkbox filter', () => {
        findCollapsibleListbox().vm.$emit('search', 'test');
        expect(actionSpies.setLabelFilterSearch).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({
            value: 'test',
          }),
        );
      });
    });

    describe('when selecting', () => {
      let mockValueForSelecting;

      beforeEach(async () => {
        createComponent();
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);
        await Vue.nextTick();
        mockValueForSelecting = findCollapsibleListbox().vm.items[2].value;
        findCollapsibleListbox().vm.$emit('select', mockValueForSelecting);
      });

      it('sends tracking information when checkbox is selected', () => {
        expect(trackingSpy).toHaveBeenCalledWith(
          'search:agreggations:label:select',
          'LabelCheckbox',
          {
            label: 'Label Key',
            property: mockValueForSelecting,
          },
        );
      });
    });

    describe('newly selected and unapplied labels show as pills above dropdown', () => {
      beforeEach(() => {
        const mockGetters = { unappliedNewLabels: jest.fn(() => MOCK_FILTERED_UNSELECTED_LABELS) };
        createComponent({}, mockGetters);
      });

      it('has correct pills', () => {
        expect(findSelectedUnappliedLabelPills()).toHaveLength(2);
      });
    });

    describe('applied labels show as pills above dropdown', () => {
      beforeEach(() => {
        const mockGetters = {
          appliedSelectedLabels: jest.fn(() => MOCK_FILTERED_UNSELECTED_LABELS),
        };
        createComponent({}, mockGetters);
      });

      it('has correct pills', () => {
        expect(findLabelPills()).toHaveLength(2);
      });
    });

    describe('closed unapplied labels show as pills above dropdown', () => {
      beforeEach(() => {
        const mockGetters = {
          unselectedLabels: jest.fn(() => MOCK_FILTERED_UNSELECTED_LABELS),
        };
        createComponent({}, mockGetters);
      });

      it('has correct pills', () => {
        expect(findClosedUnappliedPills()).toHaveLength(2);
      });
    });
  });
});
