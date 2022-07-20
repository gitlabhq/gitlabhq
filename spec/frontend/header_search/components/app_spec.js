import { GlSearchBoxByType, GlToken, GlIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

  afterEach(() => {
    wrapper.destroy();
  });

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
          findHeaderSearchInput().vm.$emit(showDropdown ? 'click' : '');
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
          findHeaderSearchInput().vm.$emit('click');
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
      });
    });

    describe.each`
      username         | showDropdown | expectedDesc
      ${null}          | ${false}     | ${HeaderSearchApp.i18n.searchInputDescribeByNoDropdown}
      ${null}          | ${true}      | ${HeaderSearchApp.i18n.searchInputDescribeByNoDropdown}
      ${MOCK_USERNAME} | ${false}     | ${HeaderSearchApp.i18n.searchInputDescribeByWithDropdown}
      ${MOCK_USERNAME} | ${true}      | ${HeaderSearchApp.i18n.searchInputDescribeByWithDropdown}
    `('Search Input Description', ({ username, showDropdown, expectedDesc }) => {
      describe(`current_username is ${username} and showDropdown is ${showDropdown}`, () => {
        beforeEach(() => {
          window.gon.current_username = username;
          createComponent();
          findHeaderSearchInput().vm.$emit(showDropdown ? 'click' : '');
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
      ${MOCK_USERNAME} | ${true}      | ${MOCK_SEARCH} | ${true}  | ${MOCK_SCOPED_SEARCH_OPTIONS}  | ${HeaderSearchApp.i18n.searchResultsLoading}
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
            findHeaderSearchInput().vm.$emit(showDropdown ? 'click' : '');
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

    describe('form wrapper', () => {
      describe.each`
        searchContext               | search         | searchOptions
        ${MOCK_SEARCH_CONTEXT_FULL} | ${null}        | ${[]}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${[]}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${null}        | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${null}        | ${[]}
      `('', ({ searchContext, search, searchOptions }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;

          createComponent({ search, searchContext }, { searchOptions: () => searchOptions });

          findHeaderSearchInput().vm.$emit('click');
        });

        const hasIcon = Boolean(searchContext?.group);
        const isSearching = Boolean(search);
        const isActive = Boolean(searchOptions.length > 0);

        it(`${hasIcon ? 'with' : 'without'} search context classes contain "${
          hasIcon ? 'has-icon' : 'has-no-icon'
        }"`, () => {
          const iconClassRegex = hasIcon ? 'has-icon' : 'has-no-icon';
          expect(findHeaderSearchForm().classes()).toContain(iconClassRegex);
        });

        it(`${isSearching ? 'with' : 'without'} search string classes contain "${
          isSearching ? 'is-searching' : 'is-not-searching'
        }"`, () => {
          const iconClassRegex = isSearching ? 'is-searching' : 'is-not-searching';
          expect(findHeaderSearchForm().classes()).toContain(iconClassRegex);
        });

        it(`${isActive ? 'with' : 'without'} search results classes contain "${
          isActive ? 'is-active' : 'is-not-active'
        }"`, () => {
          const iconClassRegex = isActive ? 'is-active' : 'is-not-active';
          expect(findHeaderSearchForm().classes()).toContain(iconClassRegex);
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
    beforeEach(() => {
      createComponent();
      window.gon.current_username = MOCK_USERNAME;
    });

    describe('Header Search Input', () => {
      describe('when dropdown is closed', () => {
        it('onFocus opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('focus');

          await nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
        });

        it('onClick opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('click');

          await nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
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

    describe('Dropdown Keyboard Navigation', () => {
      beforeEach(() => {
        findHeaderSearchInput().vm.$emit('click');
      });

      it('closes dropdown when @tab is emitted', async () => {
        expect(findHeaderSearchDropdown().exists()).toBe(true);
        findDropdownKeyboardNavigation().vm.$emit('tab');

        await nextTick();

        expect(findHeaderSearchDropdown().exists()).toBe(false);
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
        createComponent({ search });
        window.gon.current_username = MOCK_USERNAME;
        findHeaderSearchInput().vm.$emit('click');
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
        createComponent();
        window.gon.current_username = MOCK_USERNAME;
        findHeaderSearchInput().vm.$emit('click');
      });

      it('onKey-enter clicks the selected dropdown item rather than submitting a search', () => {
        findDropdownKeyboardNavigation().vm.$emit('change', MOCK_INDEX);

        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
        expect(visitUrl).toHaveBeenCalledWith(MOCK_DEFAULT_SEARCH_OPTIONS[MOCK_INDEX].url);
      });
    });
  });
});
