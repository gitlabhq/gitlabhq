import { GlForm } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_QUERY, MOCK_AGGREGATIONS } from 'jest/search/mock_data';

import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';

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
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        urlQuery: MOCK_QUERY,
        aggregations: MOCK_AGGREGATIONS,
        sidebarDirty: false,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(FiltersTemplate, {
      store,
      slots: {
        default: '<p>Filters Content</p>',
      },
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

    it('renders reset button', () => {
      expect(findResetButton().exists()).toBe(false);
    });
  });

  describe('resetButton', () => {
    describe.each`
      description                                 | sidebarDirty | queryLangFilters | exists
      ${'sidebar dirty only'}                     | ${true}      | ${[]}            | ${true}
      ${'query filters only'}                     | ${false}     | ${['JSON', 'C']} | ${false}
      ${'sidebar dirty and query filters'}        | ${true}      | ${['JSON', 'C']} | ${true}
      ${'sidebar not dirty and no query filters'} | ${false}     | ${[]}            | ${false}
    `('$description', ({ sidebarDirty, queryLangFilters, exists }) => {
      beforeEach(() => {
        getterSpies.queryLanguageFilters = jest.fn(() => queryLangFilters);

        const query = {
          ...MOCK_QUERY,
          language: queryLangFilters,
          state: undefined,
          labels: undefined,
          confidential: undefined,
        };

        createComponent({
          sidebarDirty,
          query,
          urlQuery: query,
        });
      });

      it(`button is ${exists ? 'shown' : 'hidden'}`, () => {
        expect(findResetButton().exists()).toBe(exists);
      });
    });
  });

  describe('ApplyButton', () => {
    describe('when sidebarDirty is false', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: false });
      });

      it('disables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBeDefined();
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

  describe('actions', () => {
    beforeEach(() => {
      createComponent({ sidebarDirty: true });
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
