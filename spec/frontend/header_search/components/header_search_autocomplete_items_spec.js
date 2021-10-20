import { GlDropdownItem, GlLoadingIcon, GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import {
  GROUPS_CATEGORY,
  LARGE_AVATAR_PX,
  PROJECTS_CATEGORY,
  SMALL_AVATAR_PX,
} from '~/header_search/constants';
import { MOCK_GROUPED_AUTOCOMPLETE_OPTIONS, MOCK_AUTOCOMPLETE_OPTIONS } from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchAutocompleteItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters) => {
    const store = new Vuex.Store({
      state: {
        loading: false,
        ...initialState,
      },
      getters: {
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMount(HeaderSearchAutocompleteItems, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemTitles = () => findDropdownItems().wrappers.map((w) => w.text());
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlAvatar = () => wrapper.findComponent(GlAvatar);

  describe('template', () => {
    describe('when loading is true', () => {
      beforeEach(() => {
        createComponent({ loading: true });
      });

      it('renders GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render autocomplete options', () => {
        expect(findDropdownItems()).toHaveLength(0);
      });
    });

    describe('when loading is false', () => {
      beforeEach(() => {
        createComponent({ loading: false });
      });

      it('does not render GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      describe('Dropdown items', () => {
        it('renders item for each option in autocomplete option', () => {
          expect(findDropdownItems()).toHaveLength(MOCK_AUTOCOMPLETE_OPTIONS.length);
        });

        it('renders titles correctly', () => {
          const expectedTitles = MOCK_AUTOCOMPLETE_OPTIONS.map((o) => o.label);
          expect(findDropdownItemTitles()).toStrictEqual(expectedTitles);
        });

        it('renders links correctly', () => {
          const expectedLinks = MOCK_AUTOCOMPLETE_OPTIONS.map((o) => o.url);
          expect(findDropdownItemLinks()).toStrictEqual(expectedLinks);
        });
      });
      describe.each`
        item                                                             | showAvatar | avatarSize
        ${{ data: [{ category: PROJECTS_CATEGORY, avatar_url: null }] }} | ${true}    | ${String(LARGE_AVATAR_PX)}
        ${{ data: [{ category: GROUPS_CATEGORY, avatar_url: '/123' }] }} | ${true}    | ${String(LARGE_AVATAR_PX)}
        ${{ data: [{ category: 'Help', avatar_url: '' }] }}              | ${true}    | ${String(SMALL_AVATAR_PX)}
        ${{ data: [{ category: 'Settings' }] }}                          | ${false}   | ${false}
      `('GlAvatar', ({ item, showAvatar, avatarSize }) => {
        describe(`when category is ${item.data[0].category} and avatar_url is ${item.data[0].avatar_url}`, () => {
          beforeEach(() => {
            createComponent({}, { autocompleteGroupedSearchOptions: () => [item] });
          });

          it(`should${showAvatar ? '' : ' not'} render`, () => {
            expect(findGlAvatar().exists()).toBe(showAvatar);
          });

          it(`should set avatarSize to ${avatarSize}`, () => {
            expect(findGlAvatar().exists() && findGlAvatar().attributes('size')).toBe(avatarSize);
          });
        });
      });
    });
  });
});
