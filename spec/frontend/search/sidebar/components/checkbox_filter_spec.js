import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_QUERY, MOCK_LANGUAGE_AGGREGATIONS_BUCKETS } from 'jest/search/mock_data';
import CheckboxFilter from '~/search/sidebar/components/checkbox_filter.vue';

import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';
import { convertFiltersData } from '~/search/sidebar/utils';

Vue.use(Vuex);

describe('CheckboxFilter', () => {
  let wrapper;

  const actionSpies = {
    setQuery: jest.fn(),
  };

  const defaultProps = {
    filterData: convertFiltersData(MOCK_LANGUAGE_AGGREGATIONS_BUCKETS),
  };

  const createComponent = () => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
      },
      actions: actionSpies,
    });

    wrapper = shallowMountExtended(CheckboxFilter, {
      store,
      propsData: {
        ...defaultProps,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findFormCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const fintAllCheckboxLabels = () => wrapper.findAllByTestId('label');
  const fintAllCheckboxLabelCounts = () => wrapper.findAllByTestId('labelCount');

  describe('Renders correctly', () => {
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
    it('triggers setQuery', () => {
      const filter =
        defaultProps.filterData.filters[Object.keys(defaultProps.filterData.filters)[0]].value;
      findFormCheckboxGroup().vm.$emit('input', filter);

      expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
        key: languageFilterData.filterParam,
        value: filter,
      });
    });
  });
});
