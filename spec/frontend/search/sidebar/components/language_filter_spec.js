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

    it(`renders 100 items`, async () => {
      findShowMoreButton().vm.$emit('click');

      await nextTick();

      expect(findAllCheckboxes()).toHaveLength(100);
    });

    it('sends tracking information when show more clicked', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith('search:agreggations:language:click', 'Show More', {
        label: 'All Filters',
      });
    });

    it(`renders more then 10 text`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findHasOverMax().exists()).toBe(true);
    });

    it('sends tracking information when show more clicked and max item reached', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith('search:agreggations:language:show', 'Filters', {
        label: 'Max Shown',
        property: `More than 10 filters to show`,
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
