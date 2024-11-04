import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_QUERY, MOCK_LANGUAGE_AGGREGATIONS_BUCKETS } from 'jest/search/mock_data';
import CheckboxFilter from '~/search/sidebar/components/language_filter/checkbox_filter.vue';

import { convertFiltersData } from '~/search/sidebar/utils';

Vue.use(Vuex);

describe('CheckboxFilter', () => {
  let wrapper;
  let trackingSpy;

  const actionSpies = {
    setQuery: jest.fn(),
  };

  const getterSpies = {
    queryLanguageFilters: jest.fn(() => []),
  };

  const defaultProps = {
    filtersData: convertFiltersData(MOCK_LANGUAGE_AGGREGATIONS_BUCKETS),
    trackingNamespace: 'testNameSpace',
    queryParam: 'language',
  };

  const createComponent = (Props = defaultProps) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(CheckboxFilter, {
      store,
      propsData: {
        ...Props,
      },
    });
  };

  afterEach(() => {
    unmockTracking();
  });

  const findFormCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const fintAllCheckboxLabels = () => wrapper.findAllByTestId('label');
  const fintAllCheckboxLabelCounts = () => wrapper.findAllByTestId('labelCount');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    });

    it('renders form', () => {
      expect(findFormCheckboxGroup().exists()).toBe(true);
    });

    it('renders checkbox-filter', () => {
      expect(findAllCheckboxes().exists()).toBe(true);
    });

    it('renders all checkbox-filter checkboxes', () => {
      expect(findAllCheckboxes()).toHaveLength(MOCK_LANGUAGE_AGGREGATIONS_BUCKETS.length);
    });

    it('renders correctly label for the element', () => {
      expect(fintAllCheckboxLabels().at(0).text()).toBe(MOCK_LANGUAGE_AGGREGATIONS_BUCKETS[0].key);
    });

    it('renders correctly count for the element', () => {
      expect(fintAllCheckboxLabelCounts().at(0).text()).toBe(
        MOCK_LANGUAGE_AGGREGATIONS_BUCKETS[0].count.toString(),
      );
    });
  });

  describe('actions', () => {
    const checkedLanguageName = MOCK_LANGUAGE_AGGREGATIONS_BUCKETS[0].key;

    beforeEach(() => {
      defaultProps.filtersData = convertFiltersData(MOCK_LANGUAGE_AGGREGATIONS_BUCKETS.slice(0, 3));
      CheckboxFilter.computed.selectedFilter.get = jest.fn(() => checkedLanguageName);

      createComponent();
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      findFormCheckboxGroup().vm.$emit('input', checkedLanguageName);
    });

    it('triggers setQuery', () => {
      expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
        key: 'language',
        value: checkedLanguageName,
      });
    });

    it('sends tracking information when setQuery', () => {
      findFormCheckboxGroup().vm.$emit('input', checkedLanguageName);
      expect(trackingSpy).toHaveBeenCalledWith(defaultProps.trackingNamespace, 'checkbox', {
        label: 'set',
        property: checkedLanguageName,
      });
    });
  });
});
