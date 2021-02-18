import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { MOCK_GROUPS, MOCK_GROUP, MOCK_QUERY } from 'jest/search/mock_data';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
import { ANY_OPTION, GROUP_DATA } from '~/search/topbar/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Global Search Searchable Dropdown', () => {
  let wrapper;

  const defaultProps = {
    headerText: GROUP_DATA.headerText,
    selectedDisplayValue: GROUP_DATA.selectedDisplayValue,
    itemsDisplayValue: GROUP_DATA.itemsDisplayValue,
    loading: false,
    selectedItem: ANY_OPTION,
    items: [],
  };

  const createComponent = (initialState, props, mountFn = shallowMount) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
    });

    wrapper = mountFn(SearchableDropdown, {
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

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().find(GlSearchBoxByType);
  const findDropdownText = () => findGlDropdown().find('.dropdown-toggle-text');
  const findDropdownItems = () => findGlDropdown().findAll(GlDropdownItem);
  const findDropdownItemsText = () => findDropdownItems().wrappers.map((w) => w.text());
  const findAnyDropdownItem = () => findDropdownItems().at(0);
  const findFirstGroupDropdownItem = () => findDropdownItems().at(1);
  const findLoader = () => wrapper.find(GlSkeletonLoader);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    describe('findGlDropdownSearch', () => {
      it('renders always', () => {
        expect(findGlDropdownSearch().exists()).toBe(true);
      });

      it('has debounce prop', () => {
        expect(findGlDropdownSearch().attributes('debounce')).toBe('500');
      });

      describe('onSearch', () => {
        const search = 'test search';

        beforeEach(() => {
          findGlDropdownSearch().vm.$emit('input', search);
        });

        it('$emits @search when input event is fired from GlSearchBoxByType', () => {
          expect(wrapper.emitted('search')[0]).toEqual([search]);
        });
      });
    });

    describe('findDropdownItems', () => {
      describe('when loading is false', () => {
        beforeEach(() => {
          createComponent({}, { items: MOCK_GROUPS });
        });

        it('does not render loader', () => {
          expect(findLoader().exists()).toBe(false);
        });

        it('renders an instance for each namespace', () => {
          const resultsIncludeAny = ['Any'].concat(MOCK_GROUPS.map((n) => n.full_name));
          expect(findDropdownItemsText()).toStrictEqual(resultsIncludeAny);
        });
      });

      describe('when loading is true', () => {
        beforeEach(() => {
          createComponent({}, { loading: true, items: MOCK_GROUPS });
        });

        it('does render loader', () => {
          expect(findLoader().exists()).toBe(true);
        });

        it('renders only Any in dropdown', () => {
          expect(findDropdownItemsText()).toStrictEqual(['Any']);
        });
      });

      describe('when item is selected', () => {
        beforeEach(() => {
          createComponent({}, { items: MOCK_GROUPS, selectedItem: MOCK_GROUPS[0] });
        });

        it('marks the dropdown as checked', () => {
          expect(findFirstGroupDropdownItem().attributes('ischecked')).toBe('true');
        });
      });
    });

    describe('Dropdown Text', () => {
      describe('when selectedItem is any', () => {
        beforeEach(() => {
          createComponent({}, {}, mount);
        });

        it('sets dropdown text to Any', () => {
          expect(findDropdownText().text()).toBe(ANY_OPTION.name);
        });
      });

      describe('selectedItem is set', () => {
        beforeEach(() => {
          createComponent({}, { selectedItem: MOCK_GROUP }, mount);
        });

        it('sets dropdown text to the selectedItem selectedDisplayValue', () => {
          expect(findDropdownText().text()).toBe(MOCK_GROUP[GROUP_DATA.selectedDisplayValue]);
        });
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent({}, { items: MOCK_GROUPS });
    });

    it('clicking "Any" dropdown item $emits @change with ANY_OPTION', () => {
      findAnyDropdownItem().vm.$emit('click');

      expect(wrapper.emitted('change')[0]).toEqual([ANY_OPTION]);
    });

    it('clicking result dropdown item $emits @change with result', () => {
      findFirstGroupDropdownItem().vm.$emit('click');

      expect(wrapper.emitted('change')[0]).toEqual([MOCK_GROUPS[0]]);
    });
  });
});
