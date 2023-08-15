import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_QUERY,
  MOCK_AGGREGATIONS,
  MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
} from 'jest/search/mock_data';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import CheckboxFilter from '~/search/sidebar/components/language_filter/checkbox_filter.vue';

import {
  TRACKING_LABEL_SHOW_MORE,
  TRACKING_PROPERTY_MAX,
  TRACKING_LABEL_MAX,
  TRACKING_LABEL_FILTERS,
  TRACKING_ACTION_SHOW,
  TRACKING_ACTION_CLICK,
  TRACKING_LABEL_ALL,
} from '~/search/sidebar/components/language_filter/tracking';

import { MAX_ITEM_LENGTH } from '~/search/sidebar/components/language_filter/data';

Vue.use(Vuex);

describe('GlobalSearchSidebarLanguageFilter', () => {
  let wrapper;
  let trackingSpy;

  const actionSpies = {
    fetchAllAggregation: jest.fn(),
    applyQuery: jest.fn(),
  };

  const getterSpies = {
    languageAggregationBuckets: jest.fn(() => MOCK_LANGUAGE_AGGREGATIONS_BUCKETS),
    queryLanguageFilters: jest.fn(() => []),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        urlQuery: MOCK_QUERY,
        aggregations: MOCK_AGGREGATIONS,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(LanguageFilter, {
      store,
      stubs: {
        CheckboxFilter,
      },
    });
  };

  const findCheckboxFilter = () => wrapper.findComponent(CheckboxFilter);
  const findShowMoreButton = () => wrapper.findByTestId('show-more-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findHasOverMax = () => wrapper.findByTestId('has-over-max-text');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('renders checkbox-filter', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders all checkbox-filter checkboxes', () => {
      // 11th checkbox is hidden
      expect(findAllCheckboxes()).toHaveLength(10);
    });

    it('renders Show More button', () => {
      expect(findShowMoreButton().exists()).toBe(true);
    });

    it("doesn't render Alert", () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('Show All button works', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it(`renders ${MAX_ITEM_LENGTH} amount of items`, async () => {
      findShowMoreButton().vm.$emit('click');

      await nextTick();

      expect(findAllCheckboxes()).toHaveLength(MAX_ITEM_LENGTH);
    });

    it('sends tracking information when show more clicked', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_CLICK, TRACKING_LABEL_SHOW_MORE, {
        label: TRACKING_LABEL_ALL,
      });
    });

    it(`renders more then ${MAX_ITEM_LENGTH} text`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findHasOverMax().exists()).toBe(true);
    });

    it('sends tracking information when show more clicked and max item reached', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_ACTION_SHOW, TRACKING_LABEL_FILTERS, {
        label: TRACKING_LABEL_MAX,
        property: TRACKING_PROPERTY_MAX,
      });
    });

    it(`doesn't render show more button after click`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findShowMoreButton().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent({});
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });
    afterEach(() => {
      unmockTracking();
    });

    it('uses getter languageAggregationBuckets', () => {
      expect(getterSpies.languageAggregationBuckets).toHaveBeenCalled();
    });

    it('uses action fetchAllAggregation', () => {
      expect(actionSpies.fetchAllAggregation).toHaveBeenCalled();
    });
  });
});
