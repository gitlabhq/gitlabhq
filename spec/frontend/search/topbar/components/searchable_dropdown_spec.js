import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_GROUPS, MOCK_GROUP, MOCK_QUERY } from 'jest/search/mock_data';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
import SearchableDropdownItem from '~/search/topbar/components/searchable_dropdown_item.vue';
import { ANY_OPTION, GROUP_DATA } from '~/search/topbar/constants';

Vue.use(Vuex);

describe('Global Search Searchable Dropdown', () => {
  let wrapper;

  const defaultProps = {
    headerText: GROUP_DATA.headerText,
    name: GROUP_DATA.name,
    fullName: GROUP_DATA.fullName,
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
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().findComponent(GlSearchBoxByType);
  const findDropdownText = () => findGlDropdown().find('.dropdown-toggle-text');
  const findSearchableDropdownItems = () =>
    findGlDropdown().findAllComponents(SearchableDropdownItem);
  const findAnyDropdownItem = () => findGlDropdown().findComponent(GlDropdownItem);
  const findFirstGroupDropdownItem = () => findSearchableDropdownItems().at(0);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

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

        it('renders the Any Dropdown', () => {
          expect(findAnyDropdownItem().exists()).toBe(true);
        });

        it('renders SearchableDropdownItem for each item', () => {
          expect(findSearchableDropdownItems()).toHaveLength(MOCK_GROUPS.length);
        });
      });

      describe('when loading is true', () => {
        beforeEach(() => {
          createComponent({}, { loading: true, items: MOCK_GROUPS });
        });

        it('does render loader', () => {
          expect(findLoader().exists()).toBe(true);
        });

        it('renders the Any Dropdown', () => {
          expect(findAnyDropdownItem().exists()).toBe(true);
        });

        it('does not render SearchableDropdownItem', () => {
          expect(findSearchableDropdownItems()).toHaveLength(0);
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

        it('sets dropdown text to the selectedItem name', () => {
          expect(findDropdownText().text()).toBe(MOCK_GROUP[GROUP_DATA.name]);
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

    it('on SearchableDropdownItem @change, the wrapper $emits change with the item', () => {
      findFirstGroupDropdownItem().vm.$emit('change', MOCK_GROUPS[0]);

      expect(wrapper.emitted('change')[0]).toEqual([MOCK_GROUPS[0]]);
    });

    describe('opening the dropdown', () => {
      describe('for the first time', () => {
        beforeEach(() => {
          findGlDropdown().vm.$emit('show');
        });

        it('$emits @search and @first-open', () => {
          expect(wrapper.emitted('search')[0]).toStrictEqual([wrapper.vm.searchText]);
          expect(wrapper.emitted('first-open')[0]).toStrictEqual([]);
        });
      });

      describe('not for the first time', () => {
        beforeEach(() => {
          wrapper.setData({ hasBeenOpened: true });
          findGlDropdown().vm.$emit('show');
        });

        it('$emits @search and not @first-open', () => {
          expect(wrapper.emitted('search')[0]).toStrictEqual([wrapper.vm.searchText]);
          expect(wrapper.emitted('first-open')).toBeUndefined();
        });
      });
    });
  });
});
