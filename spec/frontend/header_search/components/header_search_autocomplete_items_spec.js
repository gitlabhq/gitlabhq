import { GlDropdownItem, GlLoadingIcon, GlAvatar, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import {
  GROUPS_CATEGORY,
  LARGE_AVATAR_PX,
  PROJECTS_CATEGORY,
  SMALL_AVATAR_PX,
} from '~/header_search/constants';
import { MOCK_GROUPED_AUTOCOMPLETE_OPTIONS, MOCK_SORTED_AUTOCOMPLETE_OPTIONS } from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchAutocompleteItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
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
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownItemTitles = () => findDropdownItems().wrappers.map((w) => w.text());
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlAvatar = () => wrapper.findComponent(GlAvatar);
  const findGlAlert = () => wrapper.findComponent(GlAlert);

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

    describe('when api returns error', () => {
      beforeEach(() => {
        createComponent({ autocompleteError: true });
      });

      it('renders Alert', () => {
        expect(findGlAlert().exists()).toBe(true);
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
          expect(findDropdownItems()).toHaveLength(MOCK_SORTED_AUTOCOMPLETE_OPTIONS.length);
        });

        it('renders titles correctly', () => {
          const expectedTitles = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.label);
          expect(findDropdownItemTitles()).toStrictEqual(expectedTitles);
        });

        it('renders links correctly', () => {
          const expectedLinks = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.url);
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

    describe.each`
      currentFocusedOption                   | isFocused | ariaSelected
      ${null}                                | ${false}  | ${undefined}
      ${{ html_id: 'not-a-match' }}          | ${false}  | ${undefined}
      ${MOCK_SORTED_AUTOCOMPLETE_OPTIONS[0]} | ${true}   | ${'true'}
    `('isOptionFocused', ({ currentFocusedOption, isFocused, ariaSelected }) => {
      describe(`when currentFocusedOption.html_id is ${currentFocusedOption?.html_id}`, () => {
        beforeEach(() => {
          createComponent({}, {}, { currentFocusedOption });
        });

        it(`should${isFocused ? '' : ' not'} have gl-bg-gray-50 applied`, () => {
          expect(findFirstDropdownItem().classes('gl-bg-gray-50')).toBe(isFocused);
        });

        it(`sets "aria-selected to ${ariaSelected}`, () => {
          expect(findFirstDropdownItem().attributes('aria-selected')).toBe(ariaSelected);
        });
      });
    });
  });

  describe('watchers', () => {
    describe('currentFocusedOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('when focused changes to existing element calls scroll into view on the newly focused element', async () => {
        const focusedElement = findFirstDropdownItem().element;
        const scrollSpy = jest.spyOn(focusedElement, 'scrollIntoView');

        wrapper.setProps({ currentFocusedOption: MOCK_SORTED_AUTOCOMPLETE_OPTIONS[0] });

        await nextTick();

        expect(scrollSpy).toHaveBeenCalledWith(false);
        scrollSpy.mockRestore();
      });
    });
  });
});
