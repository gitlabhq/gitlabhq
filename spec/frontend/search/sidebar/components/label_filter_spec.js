import {
  GlAlert,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlLabel,
  GlDropdownForm,
  GlFormCheckboxGroup,
  GlDropdownSectionHeader,
  GlDropdownDivider,
} from '@gitlab/ui';
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
import LabelDropdownItems from '~/search/sidebar/components/label_filter/label_dropdown_items.vue';

import * as actions from '~/search/store/actions';
import * as getters from '~/search/store/getters';
import mutations from '~/search/store/mutations';
import createState from '~/search/store/state';

import {
  TRACKING_LABEL_FILTER,
  TRACKING_LABEL_DROPDOWN,
  TRACKING_LABEL_CHECKBOX,
  TRACKING_ACTION_SELECT,
  TRACKING_ACTION_SHOW,
} from '~/search/sidebar/components/label_filter/tracking';

import { labelFilterData } from '~/search/sidebar/components/label_filter/data';

import {
  RECEIVE_AGGREGATIONS_SUCCESS,
  REQUEST_AGGREGATIONS,
  RECEIVE_AGGREGATIONS_ERROR,
} from '~/search/store/mutation_types';

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
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownForm = () => wrapper.findComponent(GlDropdownForm);
  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findDropdownSectionHeader = () => wrapper.findComponent(GlDropdownSectionHeader);
  const findDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findCheckboxFilter = () => wrapper.findAllComponents(LabelDropdownItems);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNoLabelsFoundMessage = () => wrapper.findByTestId('no-labels-found-message');

  const findLabelPills = () => wrapper.findAllComponentsByTestId('label');
  const findSelectedUappliedLavelPills = () => wrapper.findAllComponentsByTestId('unapplied-label');
  const findClosedUnappliedPills = () => wrapper.findAllComponentsByTestId('unselected-label');

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

    it('renders search box', () => {
      expect(findSearchBox().exists()).toBe(true);
    });

    it("doesn't render dropdown form", () => {
      expect(findDropdownForm().exists()).toBe(false);
    });

    it("doesn't render checkbox group", () => {
      expect(findCheckboxGroup().exists()).toBe(false);
    });

    it("doesn't render dropdown section header", () => {
      expect(findDropdownSectionHeader().exists()).toBe(false);
    });

    it("doesn't render divider", () => {
      expect(findDivider().exists()).toBe(false);
    });

    it("doesn't render checkbox filter", () => {
      expect(findCheckboxFilter().exists()).toBe(false);
    });

    it("doesn't render alert", () => {
      expect(findAlert().exists()).toBe(false);
    });

    it("doesn't render loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('Renders correctly opened', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);

      await nextTick();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      findSearchBox().vm.$emit('focusin');
    });

    afterEach(() => {
      unmockTracking();
    });

    it('renders component title', () => {
      expect(findComponentTitle().exists()).toBe(true);
    });

    it('renders selected labels above search box', () => {
      // default data need to provide at least two selected labels
      expect(findAllSelectedLabelsAbove().exists()).toBe(true);
      expect(findAllSelectedLabelsAbove()).toHaveLength(2);
    });

    it('renders search box', () => {
      expect(findSearchBox().exists()).toBe(true);
    });

    it('renders dropdown form', () => {
      expect(findDropdownForm().exists()).toBe(true);
    });

    it('renders checkbox group', () => {
      expect(findCheckboxGroup().exists()).toBe(true);
    });

    it('renders dropdown section header', () => {
      expect(findDropdownSectionHeader().exists()).toBe(true);
    });

    it('renders divider', () => {
      expect(findDivider().exists()).toBe(true);
    });

    it('renders checkbox filter', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it("doesn't render alert", () => {
      expect(findAlert().exists()).toBe(false);
    });

    it("doesn't render loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('sends tracking information when dropdown is opened', () => {
      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_SHOW, TRACKING_LABEL_DROPDOWN, {
        label: TRACKING_LABEL_DROPDOWN,
      });
    });
  });

  describe('Renders loading state correctly', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(REQUEST_AGGREGATIONS);
      await Vue.nextTick();

      findSearchBox().vm.$emit('focusin');
    });

    it('renders checkbox filter', () => {
      expect(findCheckboxFilter().exists()).toBe(false);
    });

    it("doesn't render alert", () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('Renders no-labels state correctly', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(REQUEST_AGGREGATIONS);
      await Vue.nextTick();

      findSearchBox().vm.$emit('focusin');
      findSearchBox().vm.$emit('input', 'ssssssss');
    });

    it('renders checkbox filter', () => {
      expect(findCheckboxFilter().exists()).toBe(false);
    });

    it("doesn't render alert", () => {
      expect(findAlert().exists()).toBe(false);
    });

    it("doesn't render items", () => {
      expect(findAllSelectedLabelsAbove().exists()).toBe(false);
    });

    it('renders no labels found text', () => {
      expect(findNoLabelsFoundMessage().exists()).toBe(true);
    });
  });

  describe('Renders error state correctly', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(RECEIVE_AGGREGATIONS_ERROR);
      await Vue.nextTick();

      findSearchBox().vm.$emit('focusin');
    });

    it("doesn't render checkbox filter", () => {
      expect(findCheckboxFilter().exists()).toBe(false);
    });

    it('renders alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it("doesn't render loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
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

    describe('Closing label works correctly', () => {
      beforeEach(async () => {
        createComponent();
        store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);
        await Vue.nextTick();
      });

      it('renders checkbox filter', async () => {
        await findAllSelectedLabelsAbove().at(0).find('.btn-reset').trigger('click');
        expect(actionSpies.closeLabel).toHaveBeenCalled();
      });
    });

    describe('label search input box works properly', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders checkbox filter', () => {
        findSearchBox().find('input').setValue('test');
        expect(actionSpies.setLabelFilterSearch).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({
            value: 'test',
          }),
        );
      });
    });

    describe('dropdown checkboxes work', () => {
      beforeEach(async () => {
        createComponent();
        store.commit(RECEIVE_AGGREGATIONS_SUCCESS, MOCK_LABEL_AGGREGATIONS.data);
        await Vue.nextTick();

        await findSearchBox().vm.$emit('focusin');
        await Vue.nextTick();

        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        await findCheckboxGroup().vm.$emit('input', 6);
        await Vue.nextTick();
      });

      it('trigger event', () => {
        expect(actionSpies.setQuery).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({ key: labelFilterData?.filterParam, value: 6 }),
        );
      });

      it('sends tracking information when checkbox is selected', () => {
        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_SELECT, TRACKING_LABEL_CHECKBOX, {
          label: TRACKING_LABEL_FILTER,
          property: 6,
        });
      });
    });

    describe('newly selected and unapplied labels show as pills above dropdown', () => {
      beforeEach(() => {
        const mockGetters = { unappliedNewLabels: jest.fn(() => MOCK_FILTERED_UNSELECTED_LABELS) };
        createComponent({}, mockGetters);
      });

      it('has correct pills', () => {
        expect(findSelectedUappliedLavelPills()).toHaveLength(2);
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
