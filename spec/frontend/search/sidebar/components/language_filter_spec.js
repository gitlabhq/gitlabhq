import { GlAlert, GlFormCheckbox, GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_QUERY,
  MOCK_AGGREGATIONS,
  MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
} from 'jest/search/mock_data';
import LanguageFilter from '~/search/sidebar/components/language_filter.vue';
import CheckboxFilter from '~/search/sidebar/components/checkbox_filter.vue';
import { MAX_ITEM_LENGTH } from '~/search/sidebar/constants/language_filter_data';

Vue.use(Vuex);

describe('GlobalSearchSidebarLanguageFilter', () => {
  let wrapper;

  const actionSpies = {
    fetchLanguageAggregation: jest.fn(),
    applyQuery: jest.fn(),
  };

  const getterSpies = {
    langugageAggregationBuckets: jest.fn(() => MOCK_LANGUAGE_AGGREGATIONS_BUCKETS),
    queryLangugageFilters: jest.fn(() => []),
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

  const findForm = () => wrapper.findComponent(GlForm);
  const findCheckboxFilter = () => wrapper.findComponent(CheckboxFilter);
  const findApplyButton = () => wrapper.findByTestId('apply-button');
  const findResetButton = () => wrapper.findByTestId('reset-button');
  const findShowMoreButton = () => wrapper.findByTestId('show-more-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findHasOverMax = () => wrapper.findByTestId('has-over-max-text');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('renders checkbox-filter', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders all checkbox-filter checkboxes', () => {
      // 11th checkbox is hidden
      expect(findAllCheckboxes()).toHaveLength(10);
    });

    it('renders ApplyButton', () => {
      expect(findApplyButton().exists()).toBe(true);
    });

    it('renders Show More button', () => {
      expect(findShowMoreButton().exists()).toBe(true);
    });

    it("doesn't render Alert", () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('resetButton', () => {
    describe.each`
      description                          | sidebarDirty | queryFilters     | isDisabled
      ${'sidebar dirty only'}              | ${true}      | ${[]}            | ${undefined}
      ${'query filters only'}              | ${false}     | ${['JSON', 'C']} | ${undefined}
      ${'sidebar dirty and query filters'} | ${true}      | ${['JSON', 'C']} | ${undefined}
      ${'no sidebar and no query filters'} | ${false}     | ${[]}            | ${'true'}
    `('$description', ({ sidebarDirty, queryFilters, isDisabled }) => {
      beforeEach(() => {
        getterSpies.queryLangugageFilters = jest.fn(() => queryFilters);
        createComponent({ sidebarDirty, query: { ...MOCK_QUERY, language: queryFilters } });
      });

      it(`button is ${isDisabled ? 'enabled' : 'disabled'}`, () => {
        expect(findResetButton().attributes('disabled')).toBe(isDisabled);
      });
    });
  });

  describe('ApplyButton', () => {
    describe('when sidebarDirty is false', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: false });
      });

      it('disables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBe('true');
      });
    });

    describe('when sidebarDirty is true', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: true });
      });

      it('enables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBe(undefined);
      });
    });
  });

  describe('Show All button works', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders ${MAX_ITEM_LENGTH} amount of items`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findAllCheckboxes()).toHaveLength(MAX_ITEM_LENGTH);
    });

    it(`renders more then ${MAX_ITEM_LENGTH} text`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findHasOverMax().exists()).toBe(true);
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
    });

    it('uses getter langugageAggregationBuckets', () => {
      expect(getterSpies.langugageAggregationBuckets).toHaveBeenCalled();
    });

    it('uses action fetchLanguageAggregation', () => {
      expect(actionSpies.fetchLanguageAggregation).toHaveBeenCalled();
    });

    it('clicking ApplyButton calls applyQuery', () => {
      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(actionSpies.applyQuery).toHaveBeenCalled();
    });
  });
});
