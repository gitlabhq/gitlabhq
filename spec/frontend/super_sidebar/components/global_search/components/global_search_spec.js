import { GlModal, GlSearchBoxByType, GlToken, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__, sprintf } from '~/locale';
import GlobalSearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import GlobalSearchAutocompleteItems from '~/super_sidebar/components/global_search/components/global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import GlobalSearchScopedItems from '~/super_sidebar/components/global_search/components/global_search_scoped_items.vue';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  ICON_PROJECT,
  ICON_GROUP,
  ICON_SUBGROUP,
  SCOPE_TOKEN_MAX_LENGTH,
  IS_SEARCHING,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
} from '~/super_sidebar/components/global_search/constants';
import { truncate } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { ENTER_KEY } from '~/lib/utils/keys';
import {
  MOCK_SEARCH,
  MOCK_SEARCH_QUERY,
  MOCK_USERNAME,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_SEARCH_CONTEXT_FULL,
  MOCK_PROJECT,
  MOCK_GROUP,
} from '../mock_data';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

describe('GlobalSearchModal', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    fetchAutocompleteOptions: jest.fn(),
    clearAutocomplete: jest.fn(),
  };

  const deafaultMockState = {
    searchContext: {
      project: MOCK_PROJECT,
      group: MOCK_GROUP,
    },
  };

  const createComponent = (initialState, mockGetters, stubs) => {
    const store = new Vuex.Store({
      state: {
        ...deafaultMockState,
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        searchQuery: () => MOCK_SEARCH_QUERY,
        searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
        scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMountExtended(GlobalSearchModal, {
      store,
      stubs,
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

  const findGlobalSearchModal = () => wrapper.findComponent(GlModal);

  const findGlobalSearchForm = () => wrapper.findByTestId('global-search-form');
  const findGlobalSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findScopeToken = () => wrapper.findComponent(GlToken);
  const findGlobalSearchDefaultItems = () => wrapper.findComponent(GlobalSearchDefaultItems);
  const findGlobalSearchScopedItems = () => wrapper.findComponent(GlobalSearchScopedItems);
  const findGlobalSearchAutocompleteItems = () =>
    wrapper.findComponent(GlobalSearchAutocompleteItems);
  const findSearchInputDescription = () => wrapper.find(`#${SEARCH_INPUT_DESCRIPTION}`);
  const findSearchResultsDescription = () => wrapper.findByTestId(SEARCH_RESULTS_DESCRIPTION);

  describe('template', () => {
    describe('always renders', () => {
      beforeEach(() => {
        createComponent();
      });

      it('Global Search Input', () => {
        expect(findGlobalSearchInput().exists()).toBe(true);
      });

      it('Search Input Description', () => {
        expect(findSearchInputDescription().exists()).toBe(true);
      });

      it('Search Results Description', () => {
        expect(findSearchResultsDescription().exists()).toBe(true);
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
    `('Global Search Result Items', ({ search, showDefault, showScoped, showAutocomplete }) => {
      describe(`when search is ${search}`, () => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent({ search }, {});
          findGlobalSearchInput().vm.$emit('click');
        });

        it(`should${showDefault ? '' : ' not'} render the Default Items`, () => {
          expect(findGlobalSearchDefaultItems().exists()).toBe(showDefault);
        });

        it(`should${showScoped ? '' : ' not'} render the Scoped Items`, () => {
          expect(findGlobalSearchScopedItems().exists()).toBe(showScoped);
        });

        it(`should${showAutocomplete ? '' : ' not'} render the Autocomplete Items`, () => {
          expect(findGlobalSearchAutocompleteItems().exists()).toBe(showAutocomplete);
        });
      });
    });

    describe.each`
      username         | search         | loading  | searchOptions                  | expectedDesc
      ${null}          | ${'gi'}        | ${false} | ${[]}                          | ${GlobalSearchModal.i18n.MIN_SEARCH_TERM}
      ${MOCK_USERNAME} | ${'gi'}        | ${false} | ${[]}                          | ${GlobalSearchModal.i18n.MIN_SEARCH_TERM}
      ${MOCK_USERNAME} | ${''}          | ${false} | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${`${MOCK_DEFAULT_SEARCH_OPTIONS.length} default results provided. Use the up and down arrow keys to navigate search results list.`}
      ${MOCK_USERNAME} | ${MOCK_SEARCH} | ${true}  | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${GlobalSearchModal.i18n.SEARCH_RESULTS_LOADING}
      ${MOCK_USERNAME} | ${MOCK_SEARCH} | ${false} | ${MOCK_SCOPED_SEARCH_OPTIONS}  | ${`Results updated. ${MOCK_SCOPED_SEARCH_OPTIONS.length} results available. Use the up and down arrow keys to navigate search results list, or ENTER to submit.`}
      ${MOCK_USERNAME} | ${MOCK_SEARCH} | ${true}  | ${MOCK_SCOPED_SEARCH_OPTIONS}  | ${GlobalSearchModal.i18n.SEARCH_RESULTS_LOADING}
    `(
      'Search Results Description',
      ({ username, search, loading, searchOptions, expectedDesc }) => {
        describe(`search is "${search}" and loading is ${loading}`, () => {
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
          findGlobalSearchInput().vm.$emit('click');
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
        searchContext               | search         | searchOptions
        ${MOCK_SEARCH_CONTEXT_FULL} | ${null}        | ${[]}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${[]}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${MOCK_SEARCH_CONTEXT_FULL} | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${MOCK_SEARCH} | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${null}        | ${MOCK_SCOPED_SEARCH_OPTIONS}
        ${null}                     | ${null}        | ${[]}
      `('wrapper', ({ searchContext, search, searchOptions }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent({ search, searchContext }, { searchOptions: () => searchOptions });
        });

        const isSearching = search?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;

        it(`classes ${isSearching ? 'contain' : 'do not contain'} "${IS_SEARCHING}"`, () => {
          if (isSearching) {
            expect(findGlobalSearchForm().classes()).toContain(IS_SEARCHING);
            return;
          }
          if (!isSearching) {
            expect(findGlobalSearchForm().classes()).not.toContain(IS_SEARCHING);
          }
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
        findGlobalSearchInput().vm.$emit('click');
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

    describe('Global Search Input', () => {
      describe('onInput', () => {
        describe('when search has text', () => {
          beforeEach(() => {
            findGlobalSearchInput().vm.$emit('input', MOCK_SEARCH);
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
            findGlobalSearchInput().vm.$emit('input', '');
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

      describe('Submitting a search', () => {
        beforeEach(() => {
          createComponent();
        });

        it('onKey-enter submits a search', () => {
          findGlobalSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

          expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
        });

        describe('with less than min characters', () => {
          beforeEach(() => {
            createComponent({ search: 'x' });
          });

          it('onKey-enter will NOT submit a search', () => {
            findGlobalSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

            expect(visitUrl).not.toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
          });
        });
      });
    });

    describe('Modal events', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should emit `shown` event when modal shown`', () => {
        findGlobalSearchModal().vm.$emit('shown');
        expect(wrapper.emitted('shown')).toHaveLength(1);
      });

      it('should emit `hidden` event when modal hidden`', () => {
        findGlobalSearchModal().vm.$emit('hidden');
        expect(wrapper.emitted('hidden')).toHaveLength(1);
      });
    });
  });
});
