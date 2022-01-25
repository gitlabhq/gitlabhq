import { GlSearchBoxByType } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderSearchApp from '~/header_search/components/app.vue';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from '~/header_search/components/header_search_default_items.vue';
import HeaderSearchScopedItems from '~/header_search/components/header_search_scoped_items.vue';
import { SEARCH_INPUT_DESCRIPTION, SEARCH_RESULTS_DESCRIPTION } from '~/header_search/constants';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import { ENTER_KEY } from '~/lib/utils/keys';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  MOCK_SEARCH,
  MOCK_SEARCH_QUERY,
  MOCK_USERNAME,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
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
      search         | showDefault | showScoped | showAutocomplete | showDropdownNavigation
      ${null}        | ${true}     | ${false}   | ${false}         | ${true}
      ${''}          | ${true}     | ${false}   | ${false}         | ${true}
      ${MOCK_SEARCH} | ${false}    | ${true}    | ${true}          | ${true}
    `(
      'Header Search Dropdown Items',
      ({ search, showDefault, showScoped, showAutocomplete, showDropdownNavigation }) => {
        describe(`when search is ${search}`, () => {
          beforeEach(() => {
            window.gon.current_username = MOCK_USERNAME;
            createComponent({ search });
            findHeaderSearchInput().vm.$emit('click');
          });

          it(`should${showDefault ? '' : ' not'} render the Default Dropdown Items`, () => {
            expect(findHeaderSearchDefaultItems().exists()).toBe(showDefault);
          });

          it(`should${showScoped ? '' : ' not'} render the Scoped Dropdown Items`, () => {
            expect(findHeaderSearchScopedItems().exists()).toBe(showScoped);
          });

          it(`should${
            showAutocomplete ? '' : ' not'
          } render the Autocomplete Dropdown Items`, () => {
            expect(findHeaderSearchAutocompleteItems().exists()).toBe(showAutocomplete);
          });

          it(`should${
            showDropdownNavigation ? '' : ' not'
          } render the Dropdown Navigation Component`, () => {
            expect(findDropdownKeyboardNavigation().exists()).toBe(showDropdownNavigation);
          });
        });
      },
    );

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
        describe(`search is ${search}, loading is ${loading}, and showSearchDropdown is ${
          Boolean(username) && showDropdown
        }`, () => {
          beforeEach(() => {
            window.gon.current_username = username;
            createComponent({ search, loading }, { searchOptions: () => searchOptions });
            findHeaderSearchInput().vm.$emit(showDropdown ? 'click' : '');
          });

          it(`sets description to ${expectedDesc}`, () => {
            expect(findSearchResultsDescription().text()).toBe(expectedDesc);
          });
        });
      },
    );
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
    describe('currentFocusedOption', () => {
      const MOCK_INDEX = 1;

      beforeEach(() => {
        createComponent();
        window.gon.current_username = MOCK_USERNAME;
        findHeaderSearchInput().vm.$emit('click');
      });

      it(`when currentFocusIndex changes to ${MOCK_INDEX} updates the data to searchOptions[${MOCK_INDEX}]`, async () => {
        findDropdownKeyboardNavigation().vm.$emit('change', MOCK_INDEX);
        await nextTick();
        expect(wrapper.vm.currentFocusedOption).toBe(MOCK_DEFAULT_SEARCH_OPTIONS[MOCK_INDEX]);
      });
    });
  });

  describe('Submitting a search', () => {
    describe('with no currentFocusedOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('onKey-enter submits a search', async () => {
        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        await nextTick();

        expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
      });
    });

    describe('with currentFocusedOption', () => {
      const MOCK_INDEX = 1;

      beforeEach(() => {
        createComponent();
        window.gon.current_username = MOCK_USERNAME;
        findHeaderSearchInput().vm.$emit('click');
      });

      it('onKey-enter clicks the selected dropdown item rather than submitting a search', async () => {
        findDropdownKeyboardNavigation().vm.$emit('change', MOCK_INDEX);
        await nextTick();
        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
        expect(visitUrl).toHaveBeenCalledWith(MOCK_DEFAULT_SEARCH_OPTIONS[MOCK_INDEX].url);
      });
    });
  });
});
