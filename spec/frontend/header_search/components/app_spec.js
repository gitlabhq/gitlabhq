import { GlSearchBoxByType, GlToken, GlIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { s__, sprintf } from '~/locale';
import HeaderSearchApp from '~/header_search/components/app.vue';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from '~/header_search/components/header_search_default_items.vue';
import HeaderSearchScopedItems from '~/header_search/components/header_search_scoped_items.vue';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_BOX_INDEX,
  ICON_PROJECT,
  ICON_GROUP,
  ICON_SUBGROUP,
  SCOPE_TOKEN_MAX_LENGTH,
  IS_SEARCHING,
  IS_NOT_FOCUSED,
  IS_FOCUSED,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  DROPDOWN_CLOSE_TIMEOUT,
} from '~/header_search/constants';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import { ENTER_KEY } from '~/lib/utils/keys';
import { visitUrl } from '~/lib/utils/url_utility';
import { truncate } from '~/lib/utils/text_utility';
import {
  MOCK_SEARCH,
  MOCK_SEARCH_QUERY,
  MOCK_USERNAME,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_SEARCH_CONTEXT_FULL,
} from '../mock_data';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

describe('HeaderSearchApp', () => {
  let wrapper;

  jest.useFakeTimers();
  jest.spyOn(global, 'setTimeout');

  const actionSpies = {
    setSearch: jest.fn(),
    fetchAutocompleteOptions: jest.fn(),
    clearAutocomplete: jest.fn(),
  };

  const createComponent = (initialState, mockGetters) => {
    const store = new Vuex.Store({
      state: {
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        searchQuery: () => MOCK_SEARCH_QUERY,
        searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMountExtended(HeaderSearchApp, {
      store,
    });
  };

  const formatScopeName = (scopeName) => {
    if (!scopeName) {
      return false;
    }
    const searchResultsScope = s__('GlobalSearch|in %{scope}');
    return truncate(
      sprintf(searchResultsScope, {
        scope: scopeName,
      }),
      SCOPE_TOKEN_MAX_LENGTH,
    );
  };

  const findHeaderSearchForm = () => wrapper.findByTestId('header-search-form');
  const findHeaderSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findScopeToken = () => wrapper.findComponent(GlToken);
  const findHeaderSearchInputKBD = () => wrapper.find('.keyboard-shortcut-helper');
  const findHeaderSearchDropdown = () => wrapper.findByTestId('header-search-dropdown-menu');
  const findHeaderSearchDefaultItems = () => wrapper.findComponent(HeaderSearchDefaultItems);
  const findHeaderSearchScopedItems = () => wrapper.findComponent(HeaderSearchScopedItems);
  const findHeaderSearchAutocompleteItems = () =>
    wrapper.findComponent(HeaderSearchAutocompleteItems);
  const findDropdownKeyboardNavigation = () => wrapper.findComponent(DropdownKeyboardNavigation);
  const findSearchInputDescription = () => wrapper.find(`#${SEARCH_INPUT_DESCRIPTION}`);
  const findSearchResultsDescription = () => wrapper.findByTestId(SEARCH_RESULTS_DESCRIPTION);

  describe('template', () => {
    describe('always renders', () => {
      beforeEach(() => {
        createComponent();
      });

      it('Header Search Input', () => {
        expect(findHeaderSearchInput().exists()).toBe(true);
      });

      it('Header Search Input KBD hint', () => {
        expect(findHeaderSearchInputKBD().exists()).toBe(true);
        expect(findHeaderSearchInputKBD().text()).toContain('/');
        expect(findHeaderSearchInputKBD().attributes('title')).toContain(
          'Use the shortcut key <kbd>/</kbd> to start a search',
        );
      });

      it('Search Input Description', () => {
        expect(findSearchInputDescription().exists()).toBe(true);
      });

      it('Search Results Description', () => {
        expect(findSearchResultsDescription().exists()).toBe(true);
      });
    });

    describe.each`
      showDropdown | username         | showSearchDropdown
      ${false}     | ${null}          | ${false}
      ${false}     | ${MOCK_USERNAME} | ${false}
      ${true}      | ${null}          | ${false}
      ${true}      | ${MOCK_USERNAME} | ${true}
    `('Header Search Dropdown', ({ showDropdown, username, showSearchDropdown }) => {
      describe(`when showDropdown is ${showDropdown} and current_username is ${username}`, () => {
        beforeEach(() => {
          window.gon.current_username = username;
          createComponent();
          findHeaderSearchInput().vm.$emit(showDropdown ? 'focusin' : '');
        });

        it(`should${showSearchDropdown ? '' : ' not'} render`, () => {
          expect(findHeaderSearchDropdown().exists()).toBe(showSearchDropdown);
        });
      });
    });

    describe.each`
      search         | showDefault | showScoped | showAutocomplete
      ${null}        | ${true}     | ${false}   | ${false}
      ${''}          | ${true}     | ${false}   | ${false}
      ${'t'}         | ${false}    | ${false}   | ${true}
      ${'te'}        | ${false}    | ${false}   | ${true}
      ${'tes'}       | ${false}    | ${true}    | ${true}
      ${MOCK_SEARCH} | ${false}    | ${true}    | ${true}
    `('Header Search Dropdown Items', ({ search, showDefault, showScoped, showAutocomplete }) => {
      describe(`when search is ${search}`, () => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent({ search }, {});
          findHeaderSearchInput().vm.$emit('focusin');
        });

        it(`should${showDefault ? '' : ' not'} render the Default Dropdown Items`, () => {
          expect(findHeaderSearchDefaultItems().exists()).toBe(showDefault);
        });

        it(`should${showScoped ? '' : ' not'} render the Scoped Dropdown Items`, () => {
          expect(findHeaderSearchScopedItems().exists()).toBe(showScoped);
        });

        it(`should${showAutocomplete ? '' : ' not'} render the Autocomplete Dropdown Items`, () => {
          expect(findHeaderSearchAutocompleteItems().exists()).toBe(showAutocomplete);
        });

        it(`should render the Dropdown Navigation Component`, () => {
          expect(findDropdownKeyboardNavigation().exists()).toBe(true);
        });

        it(`should close the dropdown when press escape key`, async () => {
          findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: 27 }));
          jest.runAllTimers();
          await nextTick();
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          expect(wrapper.emitted().expandSearchBar.length).toBe(1);
        });
      });
    });

    describe.each`
      username         | showDropdown | expectedDesc
      ${null}          | ${false}     | ${HeaderSearchApp.i18n.SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN}
      ${null}          | ${true}      | ${HeaderSearchApp.i18n.SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN}
      ${MOCK_USERNAME} | ${false}     | ${HeaderSearchApp.i18n.SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN}
      ${MOCK_USERNAME} | ${true}      | ${HeaderSearchApp.i18n.SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN}
    `('Search Input Description', ({ username, showDropdown, expectedDesc }) => {
      describe(`current_username is ${username} and showDropdown is ${showDropdown}`, () => {
        beforeEach(() => {
          window.gon.current_username = username;
          createComponent();
          findHeaderSearchInput().vm.$emit(showDropdown ? 'focusin' : '');
        });

        it(`sets description to ${expectedDesc}`, () => {
          expect(findSearchInputDescription().text()).toBe(expectedDesc);
        });
      });
    });

    describe.each`
      username         | showDropdown | search         | loading  | searchOptions                  | expectedDesc
      ${null}          | ${true}      | ${''}          | ${false} | ${[]}                          | ${''}
      ${MOCK_USERNAME} | ${false}     | ${''}          | ${false} | ${[]}                          | ${''}
      ${MOCK_USERNAME} | ${true}      | ${''}          | ${false} | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${`${MOCK_DEFAULT_SEARCH_OPTIONS.length} default results provided. Use the up and down arrow keys to navigate search results list.`}
      ${MOCK_USERNAME} | ${true}      | ${''}          | ${true}  | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${`${MOCK_DEFAULT_SEARCH_OPTIONS.length} default results provided. Use the up and down arrow keys to navigate search results list.`}
      ${MOCK_USERNAME} | ${true}      | ${MOCK_SEARCH} | ${false} | ${MOCK_SCOPED_SEARCH_OPTIONS}  | ${`Results updated. ${MOCK_SCOPED_SEARCH_OPTIONS.length} results available. Use the up and down arrow keys to navigate search results list, or ENTER to submit.`}
      ${MOCK_USERNAME} | ${true}      | ${MOCK_SEARCH} | ${true}  | ${MOCK_SCOPED_SEARCH_OPTIONS}  | ${HeaderSearchApp.i18n.SEARCH_RESULTS_LOADING}
    `(
      'Search Results Description',
      ({ username, showDropdown, search, loading, searchOptions, expectedDesc }) => {
        describe(`search is "${search}", loading is ${loading}, and showSearchDropdown is ${showDropdown}`, () => {
          beforeEach(() => {
            window.gon.current_username = username;
            createComponent(
              {
                search,
                loading,
              },
              {
                searchOptions: () => searchOptions,
              },
            );
            findHeaderSearchInput().vm.$emit(showDropdown ? 'focusin' : '');
          });

          it(`sets description to ${expectedDesc}`, () => {
            expect(findSearchResultsDescription().text()).toBe(expectedDesc);
          });
        });
      },
    );

    describe('input box', () => {
      describe.each`
        search         | searchOptions                      | hasToken
        ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[0]]} | ${true}
        ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[1]]} | ${true}
        ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[2]]} | ${true}
        ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[3]]} | ${true}
        ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[4]]} | ${true}
        ${'te'}        | ${[MOCK_SCOPED_SEARCH_OPTIONS[5]]} | ${false}
        ${'x'}         | ${[]}                              | ${false}
      `('token', ({ search, searchOptions, hasToken }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent(
            { search },
            {
              searchOptions: () => searchOptions,
            },
          );
          findHeaderSearchInput().vm.$emit('focusin');
        });

        it(`${hasToken ? 'is' : 'is NOT'} rendered when data set has type "${
          searchOptions[0]?.html_id
        }"`, () => {
          expect(findScopeToken().exists()).toBe(hasToken);
        });

        it(`text ${hasToken ? 'is correctly' : 'is NOT'} rendered when text is "${
          searchOptions[0]?.scope || searchOptions[0]?.description
        }"`, () => {
          expect(findScopeToken().exists() && findScopeToken().text()).toBe(
            formatScopeName(searchOptions[0]?.scope || searchOptions[0]?.description),
          );
        });
      });
    });

    describe('form', () => {
      describe.each`
        searchContext               | search         | searchOptions                 | isFocused
        ${MOCK_SEARCH_CONTEXT_FULL} | ${null}        | ${[]}                         | ${true}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${[]}                         | ${true}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${true}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${false}
        ${null}                     | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${true}
        ${null}                     | ${null}        | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${true}
        ${null}                     | ${null}        | ${[]}                         | ${true}
      `('wrapper', ({ searchContext, search, searchOptions, isFocused }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent({ search, searchContext }, { searchOptions: () => searchOptions });
          if (isFocused) {
            findHeaderSearchInput().vm.$emit('focusin');
          }
        });

        const isSearching = search?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;

        it(`classes ${isSearching ? 'contain' : 'do not contain'} "${IS_SEARCHING}"`, () => {
          if (isSearching) {
            expect(findHeaderSearchForm().classes()).toContain(IS_SEARCHING);
            return;
          }
          if (!isSearching) {
            expect(findHeaderSearchForm().classes()).not.toContain(IS_SEARCHING);
          }
        });

        it(`classes ${isSearching ? 'contain' : 'do not contain'} "${
          isFocused ? IS_FOCUSED : IS_NOT_FOCUSED
        }"`, () => {
          expect(findHeaderSearchForm().classes()).toContain(
            isFocused ? IS_FOCUSED : IS_NOT_FOCUSED,
          );
        });
      });
    });

    describe.each`
      search         | searchOptions                      | hasIcon  | iconName
      ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[0]]} | ${true}  | ${ICON_PROJECT}
      ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[2]]} | ${true}  | ${ICON_GROUP}
      ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[3]]} | ${true}  | ${ICON_SUBGROUP}
      ${MOCK_SEARCH} | ${[MOCK_SCOPED_SEARCH_OPTIONS[4]]} | ${false} | ${false}
    `('token', ({ search, searchOptions, hasIcon, iconName }) => {
      beforeEach(() => {
        window.gon.current_username = MOCK_USERNAME;
        createComponent(
          { search },
          {
            searchOptions: () => searchOptions,
          },
        );
        findHeaderSearchInput().vm.$emit('focusin');
      });

      it(`icon for data set type "${searchOptions[0]?.html_id}" ${
        hasIcon ? 'is' : 'is NOT'
      } rendered`, () => {
        expect(findScopeToken().findComponent(GlIcon).exists()).toBe(hasIcon);
      });

      it(`render ${iconName ? `"${iconName}"` : 'NO'} icon for data set type "${
        searchOptions[0]?.html_id
      }"`, () => {
        expect(
          findScopeToken().findComponent(GlIcon).exists() &&
            findScopeToken().findComponent(GlIcon).attributes('name'),
        ).toBe(iconName);
      });
    });
  });

  describe('events', () => {
    describe('Header Search Input', () => {
      beforeEach(() => {
        window.gon.current_username = MOCK_USERNAME;
        createComponent();
      });

      describe('when dropdown is closed', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        });

        it('onFocusin opens dropdown and triggers snowplow event', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('focusin');

          await nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'focus_input', {
            label: 'global_search',
            property: 'navigation_top',
          });
        });

        it('onFocusout closes dropdown and triggers snowplow event', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);

          findHeaderSearchInput().vm.$emit('focusout');
          jest.runAllTimers();
          await nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(false);
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'blur_input', {
            label: 'global_search',
            property: 'navigation_top',
          });
        });
      });

      describe('onInput', () => {
        describe('when search has text', () => {
          beforeEach(() => {
            findHeaderSearchInput().vm.$emit('input', MOCK_SEARCH);
          });

          it('calls setSearch with search term', () => {
            expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), MOCK_SEARCH);
          });

          it('calls fetchAutocompleteOptions', () => {
            expect(actionSpies.fetchAutocompleteOptions).toHaveBeenCalled();
          });

          it('does not call clearAutocomplete', () => {
            expect(actionSpies.clearAutocomplete).not.toHaveBeenCalled();
          });
        });

        describe('when search is emptied', () => {
          beforeEach(() => {
            findHeaderSearchInput().vm.$emit('input', '');
          });

          it('calls setSearch with empty term', () => {
            expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), '');
          });

          it('does not call fetchAutocompleteOptions', () => {
            expect(actionSpies.fetchAutocompleteOptions).not.toHaveBeenCalled();
          });

          it('calls clearAutocomplete', () => {
            expect(actionSpies.clearAutocomplete).toHaveBeenCalled();
          });
        });
      });
    });

    describe('onFocusout dropdown', () => {
      beforeEach(() => {
        window.gon.current_username = MOCK_USERNAME;
        createComponent({ search: 'tes' }, {});
        findHeaderSearchInput().vm.$emit('focusin');
      });

      it('closes with timeout so click event gets emited', () => {
        findHeaderSearchInput().vm.$emit('focusout');

        expect(setTimeout).toHaveBeenCalledTimes(1);
        expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), DROPDOWN_CLOSE_TIMEOUT);
      });
    });
  });

  describe('computed', () => {
    describe.each`
      MOCK_INDEX          | search
      ${1}                | ${null}
      ${SEARCH_BOX_INDEX} | ${'test'}
      ${2}                | ${'test1'}
    `('currentFocusedOption', ({ MOCK_INDEX, search }) => {
      beforeEach(() => {
        window.gon.current_username = MOCK_USERNAME;
        createComponent({ search });
        findHeaderSearchInput().vm.$emit('focusin');
      });

      it(`when currentFocusIndex changes to ${MOCK_INDEX} updates the data to searchOptions[${MOCK_INDEX}]`, () => {
        findDropdownKeyboardNavigation().vm.$emit('change', MOCK_INDEX);
        expect(wrapper.vm.currentFocusedOption).toBe(MOCK_DEFAULT_SEARCH_OPTIONS[MOCK_INDEX]);
      });
    });
  });

  describe('Submitting a search', () => {
    describe('with no currentFocusedOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('onKey-enter submits a search', () => {
        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
      });
    });

    describe('with less than min characters and no dropdown results', () => {
      beforeEach(() => {
        createComponent({ search: 'x' });
      });

      it('onKey-enter will NOT submit a search', () => {
        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        expect(visitUrl).not.toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
      });
    });

    describe('with currentFocusedOption', () => {
      const MOCK_INDEX = 1;

      beforeEach(() => {
        window.gon.current_username = MOCK_USERNAME;
        createComponent();
        findHeaderSearchInput().vm.$emit('focusin');
      });

      it('onKey-enter clicks the selected dropdown item rather than submitting a search', async () => {
        await nextTick();
        findDropdownKeyboardNavigation().vm.$emit('change', MOCK_INDEX);

        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
        expect(visitUrl).toHaveBeenCalledWith(MOCK_DEFAULT_SEARCH_OPTIONS[MOCK_INDEX].url);
      });
    });
  });
});
