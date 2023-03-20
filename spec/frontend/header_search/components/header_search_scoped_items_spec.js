import { GlDropdownItem, GlToken, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import HeaderSearchScopedItems from '~/header_search/components/header_search_scoped_items.vue';
import { truncate } from '~/lib/utils/text_utility';
import { SCOPE_TOKEN_MAX_LENGTH } from '~/header_search/constants';
import { MSG_IN_ALL_GITLAB } from '~/vue_shared/global_search/constants';
import {
  MOCK_SEARCH,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchScopedItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
    const store = new Vuex.Store({
      state: {
        search: MOCK_SEARCH,
        ...initialState,
      },
      getters: {
        scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMount(HeaderSearchScopedItems, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownItemTitles = () => findDropdownItems().wrappers.map((w) => trimText(w.text()));
  const findScopeTokens = () => wrapper.findAllComponents(GlToken);
  const findScopeTokensText = () => findScopeTokens().wrappers.map((w) => trimText(w.text()));
  const findScopeTokensIcons = () =>
    findScopeTokens().wrappers.map((w) => w.findAllComponents(GlIcon));
  const findDropdownItemAriaLabels = () =>
    findDropdownItems().wrappers.map((w) => trimText(w.attributes('aria-label')));
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));

  describe('template', () => {
    describe('Dropdown items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders item for each option in scopedSearchOptions', () => {
        expect(findDropdownItems()).toHaveLength(MOCK_SCOPED_SEARCH_OPTIONS.length);
      });

      it('renders titles correctly', () => {
        findDropdownItemTitles().forEach((title) => expect(title).toContain(MOCK_SEARCH));
      });

      it('renders scope names correctly', () => {
        const expectedTitles = MOCK_SCOPED_SEARCH_OPTIONS.map((o) =>
          truncate(trimText(`in ${o.description || o.scope}`), SCOPE_TOKEN_MAX_LENGTH),
        );

        expect(findScopeTokensText()).toStrictEqual(expectedTitles);
      });

      it('renders scope icons correctly', () => {
        findScopeTokensIcons().forEach((icon, i) => {
          const w = icon.wrappers[0];
          expect(w?.attributes('name')).toBe(MOCK_SCOPED_SEARCH_OPTIONS[i].icon);
        });
      });

      it(`renders scope ${MSG_IN_ALL_GITLAB} correctly`, () => {
        expect(findScopeTokens().at(-1).findComponent(GlIcon).exists()).toBe(false);
      });

      it('renders aria-labels correctly', () => {
        const expectedLabels = MOCK_SCOPED_SEARCH_OPTIONS.map((o) =>
          trimText(`${MOCK_SEARCH} ${o.description || o.icon} ${o.scope || ''}`),
        );
        expect(findDropdownItemAriaLabels()).toStrictEqual(expectedLabels);
      });

      it('renders links correctly', () => {
        const expectedLinks = MOCK_SCOPED_SEARCH_OPTIONS.map((o) => o.url);
        expect(findDropdownItemLinks()).toStrictEqual(expectedLinks);
      });
    });

    describe.each`
      currentFocusedOption             | isFocused | ariaSelected
      ${null}                          | ${false}  | ${undefined}
      ${{ html_id: 'not-a-match' }}    | ${false}  | ${undefined}
      ${MOCK_SCOPED_SEARCH_OPTIONS[0]} | ${true}   | ${'true'}
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
});
