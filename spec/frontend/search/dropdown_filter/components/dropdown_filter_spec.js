import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { MOCK_QUERY } from 'jest/search/mock_data';
import * as urlUtils from '~/lib/utils/url_utility';
import initStore from '~/search/store';
import DropdownFilter from '~/search/dropdown_filter/components/dropdown_filter.vue';
import stateFilterData from '~/search/dropdown_filter/constants/state_filter_data';
import confidentialFilterData from '~/search/dropdown_filter/constants/confidential_filter_data';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DropdownFilter', () => {
  let wrapper;
  let store;

  const createStore = options => {
    store = initStore({ query: MOCK_QUERY, ...options });
  };

  const createComponent = (props = { filterData: stateFilterData }) => {
    wrapper = shallowMount(DropdownFilter, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownItems = () => findGlDropdown().findAll(GlDropdownItem);
  const findDropdownItemsText = () => findGlDropdownItems().wrappers.map(w => w.text());
  const firstDropDownItem = () => findGlDropdownItems().at(0);

  describe('StatusFilter', () => {
    describe('template', () => {
      describe.each`
        scope               | showDropdown
        ${'issues'}         | ${true}
        ${'merge_requests'} | ${true}
        ${'projects'}       | ${false}
        ${'milestones'}     | ${false}
        ${'users'}          | ${false}
        ${'notes'}          | ${false}
        ${'wiki_blobs'}     | ${false}
        ${'blobs'}          | ${false}
      `(`dropdown`, ({ scope, showDropdown }) => {
        beforeEach(() => {
          createStore({ query: { ...MOCK_QUERY, scope } });
          createComponent();
        });

        it(`does${showDropdown ? '' : ' not'} render when scope is ${scope}`, () => {
          expect(findGlDropdown().exists()).toBe(showDropdown);
        });
      });

      describe.each`
        initialFilter                           | label
        ${stateFilterData.filters.ANY.value}    | ${`Any ${stateFilterData.header}`}
        ${stateFilterData.filters.OPEN.value}   | ${stateFilterData.filters.OPEN.label}
        ${stateFilterData.filters.CLOSED.value} | ${stateFilterData.filters.CLOSED.label}
      `(`filter text`, ({ initialFilter, label }) => {
        describe(`when initialFilter is ${initialFilter}`, () => {
          beforeEach(() => {
            createStore({ query: { ...MOCK_QUERY, [stateFilterData.filterParam]: initialFilter } });
            createComponent();
          });

          it(`sets dropdown label to ${label}`, () => {
            expect(findGlDropdown().attributes('text')).toBe(label);
          });
        });
      });
    });

    describe('Filter options', () => {
      beforeEach(() => {
        createStore();
        createComponent();
      });

      it('renders a dropdown item for each filterOption', () => {
        expect(findDropdownItemsText()).toStrictEqual(
          stateFilterData.filterByScope[stateFilterData.scopes.ISSUES].map(v => {
            return v.label;
          }),
        );
      });

      it('clicking a dropdown item calls setUrlParams', () => {
        const filter = stateFilterData.filters[Object.keys(stateFilterData.filters)[0]].value;
        firstDropDownItem().vm.$emit('click');

        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
          page: null,
          [stateFilterData.filterParam]: filter,
        });
      });

      it('clicking a dropdown item calls visitUrl', () => {
        firstDropDownItem().vm.$emit('click');

        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('ConfidentialFilter', () => {
    describe('template', () => {
      describe.each`
        scope               | showDropdown
        ${'issues'}         | ${true}
        ${'merge_requests'} | ${false}
        ${'projects'}       | ${false}
        ${'milestones'}     | ${false}
        ${'users'}          | ${false}
        ${'notes'}          | ${false}
        ${'wiki_blobs'}     | ${false}
        ${'blobs'}          | ${false}
      `(`dropdown`, ({ scope, showDropdown }) => {
        beforeEach(() => {
          createStore({ query: { ...MOCK_QUERY, scope } });
          createComponent({ filterData: confidentialFilterData });
        });

        it(`does${showDropdown ? '' : ' not'} render when scope is ${scope}`, () => {
          expect(findGlDropdown().exists()).toBe(showDropdown);
        });
      });

      describe.each`
        initialFilter                                            | label
        ${confidentialFilterData.filters.ANY.value}              | ${`Any ${confidentialFilterData.header}`}
        ${confidentialFilterData.filters.CONFIDENTIAL.value}     | ${confidentialFilterData.filters.CONFIDENTIAL.label}
        ${confidentialFilterData.filters.NOT_CONFIDENTIAL.value} | ${confidentialFilterData.filters.NOT_CONFIDENTIAL.label}
      `(`filter text`, ({ initialFilter, label }) => {
        describe(`when initialFilter is ${initialFilter}`, () => {
          beforeEach(() => {
            createStore({
              query: { ...MOCK_QUERY, [confidentialFilterData.filterParam]: initialFilter },
            });
            createComponent({ filterData: confidentialFilterData });
          });

          it(`sets dropdown label to ${label}`, () => {
            expect(findGlDropdown().attributes('text')).toBe(label);
          });
        });
      });
    });
  });

  describe('Filter options', () => {
    beforeEach(() => {
      createStore();
      createComponent({ filterData: confidentialFilterData });
    });

    it('renders a dropdown item for each filterOption', () => {
      expect(findDropdownItemsText()).toStrictEqual(
        confidentialFilterData.filterByScope[confidentialFilterData.scopes.ISSUES].map(v => {
          return v.label;
        }),
      );
    });

    it('clicking a dropdown item calls setUrlParams', () => {
      const filter =
        confidentialFilterData.filters[Object.keys(confidentialFilterData.filters)[0]].value;
      firstDropDownItem().vm.$emit('click');

      expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
        page: null,
        [confidentialFilterData.filterParam]: filter,
      });
    });

    it('clicking a dropdown item calls visitUrl', () => {
      firstDropDownItem().vm.$emit('click');

      expect(urlUtils.visitUrl).toHaveBeenCalled();
    });
  });
});
