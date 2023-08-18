import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import { confidentialFilterData } from '~/search/sidebar/components/confidentiality_filter/data';
import { statusFilterData } from '~/search/sidebar/components/status_filter/data';

Vue.use(Vuex);

describe('RadioFilter', () => {
  let wrapper;

  const actionSpies = {
    setQuery: jest.fn(),
  };

  const defaultGetters = {
    currentScope: jest.fn(() => 'issues'),
  };

  const defaultProps = {
    filterData: statusFilterData,
  };

  const createComponent = (initialState, props = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: defaultGetters,
    });

    wrapper = shallowMount(RadioFilter, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlRadioButtonGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findGlRadioButtons = () => findGlRadioButtonGroup().findAllComponents(GlFormRadio);
  const findGlRadioButtonsText = () => findGlRadioButtons().wrappers.map((w) => w.text());

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlRadioButtonGroup always', () => {
      expect(findGlRadioButtonGroup().exists()).toBe(true);
    });

    describe('Radio Buttons', () => {
      describe('Status Filter', () => {
        it('renders a radio button for each filterOption', () => {
          expect(findGlRadioButtonsText()).toStrictEqual(
            statusFilterData.filterByScope[statusFilterData.scopes.ISSUES].map((f) => {
              return f.value === statusFilterData.filters.ANY.value
                ? `Any ${statusFilterData.header.toLowerCase()}`
                : f.label;
            }),
          );
        });

        it('clicking a radio button item calls setQuery', () => {
          const filter = statusFilterData.filters[Object.keys(statusFilterData.filters)[0]].value;
          findGlRadioButtonGroup().vm.$emit('input', filter);

          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: statusFilterData.filterParam,
            value: filter,
          });
        });
      });

      describe('Confidentiality Filter', () => {
        beforeEach(() => {
          createComponent({}, { filterData: confidentialFilterData });
        });

        it('renders a radio button for each filterOption', () => {
          expect(findGlRadioButtonsText()).toStrictEqual(
            confidentialFilterData.filterByScope[confidentialFilterData.scopes.ISSUES].map((f) => {
              return f.value === confidentialFilterData.filters.ANY.value
                ? `Any ${confidentialFilterData.header.toLowerCase()}`
                : f.label;
            }),
          );
        });

        it('clicking a radio button item calls setQuery', () => {
          const filter =
            confidentialFilterData.filters[Object.keys(confidentialFilterData.filters)[0]].value;
          findGlRadioButtonGroup().vm.$emit('input', filter);

          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: confidentialFilterData.filterParam,
            value: filter,
          });
        });
      });
    });
  });
});
