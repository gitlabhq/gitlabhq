import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { MOCK_GROUPS, MOCK_GROUP, MOCK_QUERY } from 'jest/search/mock_data';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
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

    wrapper = extendedWrapper(
      mountFn(SearchableDropdown, {
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().findComponent(GlSearchBoxByType);
  const findDropdownText = () => findGlDropdown().find('.dropdown-toggle-text');
  const findSearchableDropdownItems = () => wrapper.findAllByTestId('searchable-items');
  const findFrequentDropdownItems = () => wrapper.findAllByTestId('frequent-items');
  const findAnyDropdownItem = () => findGlDropdown().findComponent(GlDropdownItem);
  const findFirstSearchableDropdownItem = () => findSearchableDropdownItems().at(0);
  const findFirstFrequentDropdownItem = () => findFrequentDropdownItems().at(0);
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

    describe('Searchable Dropdown Items', () => {
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

        it('renders searchable dropdown item for each item', () => {
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

        it('does not render searchable dropdown items', () => {
          expect(findSearchableDropdownItems()).toHaveLength(0);
        });
      });
    });

    describe.each`
      searchText | frequentItems  | length
      ${''}      | ${[]}          | ${0}
      ${''}      | ${MOCK_GROUPS} | ${MOCK_GROUPS.length}
      ${'test'}  | ${[]}          | ${0}
      ${'test'}  | ${MOCK_GROUPS} | ${0}
    `('Frequent Dropdown Items', ({ searchText, frequentItems, length }) => {
      describe(`when search is ${searchText} and frequentItems length is ${frequentItems.length}`, () => {
        beforeEach(() => {
          createComponent({}, { frequentItems });
          wrapper.setData({ searchText });
        });

        it(`should${length ? '' : ' not'} render frequent dropdown items`, () => {
          expect(findFrequentDropdownItems()).toHaveLength(length);
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
      createComponent({}, { items: MOCK_GROUPS, frequentItems: MOCK_GROUPS });
    });

    it('clicking "Any" dropdown item $emits @change with ANY_OPTION', () => {
      findAnyDropdownItem().vm.$emit('click');

      expect(wrapper.emitted('change')[0]).toEqual([ANY_OPTION]);
    });

    it('on searchable item @change, the wrapper $emits change with the item', () => {
      findFirstSearchableDropdownItem().vm.$emit('change', MOCK_GROUPS[0]);

      expect(wrapper.emitted('change')[0]).toEqual([MOCK_GROUPS[0]]);
    });

    it('on frequent item @change, the wrapper $emits change with the item', () => {
      findFirstFrequentDropdownItem().vm.$emit('change', MOCK_GROUPS[0]);

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
