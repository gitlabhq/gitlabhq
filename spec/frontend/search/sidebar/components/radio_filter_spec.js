import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { MOCK_QUERY } from 'jest/search/mock_data';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import { stateFilterData } from '~/search/sidebar/constants/state_filter_data';
import { confidentialFilterData } from '~/search/sidebar/constants/confidential_filter_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RadioFilter', () => {
  let wrapper;

  const actionSpies = {
    setQuery: jest.fn(),
  };

  const defaultProps = {
    filterData: stateFilterData,
  };

  const createComponent = (initialState, props = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(RadioFilter, {
      localVue,
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlRadioButtonGroup = () => wrapper.find(GlFormRadioGroup);
  const findGlRadioButtons = () => findGlRadioButtonGroup().findAll(GlFormRadio);
  const findGlRadioButtonsText = () => findGlRadioButtons().wrappers.map(w => w.text());

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
            stateFilterData.filterByScope[stateFilterData.scopes.ISSUES].map(f => {
              return f.value === stateFilterData.filters.ANY.value
                ? `Any ${stateFilterData.header.toLowerCase()}`
                : f.label;
            }),
          );
        });

        it('clicking a radio button item calls setQuery', () => {
          const filter = stateFilterData.filters[Object.keys(stateFilterData.filters)[0]].value;
          findGlRadioButtonGroup().vm.$emit('input', filter);

          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: stateFilterData.filterParam,
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
            confidentialFilterData.filterByScope[confidentialFilterData.scopes.ISSUES].map(f => {
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
