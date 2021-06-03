import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlSkeletonLoader,
  GlAvatar,
} from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { MOCK_GROUPS, MOCK_GROUP, MOCK_QUERY } from 'jest/search/mock_data';
import { truncateNamespace } from '~/lib/utils/text_utility';
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
    wrapper = null;
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().find(GlSearchBoxByType);
  const findDropdownText = () => findGlDropdown().find('.dropdown-toggle-text');
  const findDropdownItems = () => findGlDropdown().findAll(GlDropdownItem);
  const findDropdownItemTitles = () => wrapper.findAllByTestId('item-title');
  const findDropdownItemNamespaces = () => wrapper.findAllByTestId('item-namespace');
  const findDropdownAvatars = () => wrapper.findAllComponents(GlAvatar);
  const findAnyDropdownItem = () => findDropdownItems().at(0);
  const findFirstGroupDropdownItem = () => findDropdownItems().at(1);
  const findLoader = () => wrapper.find(GlSkeletonLoader);

  const findDropdownItemTitlesText = () => findDropdownItemTitles().wrappers.map((w) => w.text());
  const findDropdownItemNamespacesText = () =>
    findDropdownItemNamespaces().wrappers.map((w) => w.text());
  const findDropdownAvatarUrls = () => findDropdownAvatars().wrappers.map((w) => w.props('src'));

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

        it('renders titles correctly including Any', () => {
          const resultsIncludeAny = ['Any'].concat(MOCK_GROUPS.map((n) => n[GROUP_DATA.name]));
          expect(findDropdownItemTitlesText()).toStrictEqual(resultsIncludeAny);
        });

        it('renders namespaces truncated correctly', () => {
          const namespaces = MOCK_GROUPS.map((n) => truncateNamespace(n[GROUP_DATA.fullName]));
          expect(findDropdownItemNamespacesText()).toStrictEqual(namespaces);
        });

        it('renders GlAvatar for each item', () => {
          const avatars = MOCK_GROUPS.map((n) => n.avatar_url);
          expect(findDropdownAvatarUrls()).toStrictEqual(avatars);
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
          expect(findDropdownItemTitlesText()).toStrictEqual(['Any']);
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

    it('clicking result dropdown item $emits @change with result', () => {
      findFirstGroupDropdownItem().vm.$emit('click');

      expect(wrapper.emitted('change')[0]).toEqual([MOCK_GROUPS[0]]);
    });
  });
});
