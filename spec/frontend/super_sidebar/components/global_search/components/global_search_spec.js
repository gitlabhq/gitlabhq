import { GlModal, GlSearchBoxByType, GlToken, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__, sprintf } from '~/locale';
import GlobalSearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import GlobalSearchAutocompleteItems from '~/super_sidebar/components/global_search/components/global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import GlobalSearchScopedItems from '~/super_sidebar/components/global_search/components/global_search_scoped_items.vue';
import FakeSearchInput from '~/super_sidebar/components/global_search/command_palette/fake_search_input.vue';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import {
  SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
  COMMON_HANDLES,
  PATH_HANDLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  ICON_PROJECT,
  ICON_GROUP,
  ICON_SUBGROUP,
  SCOPE_TOKEN_MAX_LENGTH,
} from '~/super_sidebar/components/global_search/constants';
import { SEARCH_GITLAB } from '~/vue_shared/global_search/constants';
import { truncate } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { ENTER_KEY } from '~/lib/utils/keys';
import {
  MOCK_SEARCH,
  MOCK_SEARCH_QUERY,
  MOCK_USERNAME,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
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

  const defaultMockGetters = {
    searchQuery: () => MOCK_SEARCH_QUERY,
    searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
    scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
  };

  const createComponent = (
    initialState = deafaultMockState,
    mockGetters = defaultMockGetters,
    stubs,
    glFeatures = { commandPalette: false },
  ) => {
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
      provide: { glFeatures },
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

  const findGlobalSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findScopeToken = () => wrapper.findComponent(GlToken);
  const findGlobalSearchDefaultItems = () => wrapper.findComponent(GlobalSearchDefaultItems);
  const findGlobalSearchScopedItems = () => wrapper.findComponent(GlobalSearchScopedItems);
  const findGlobalSearchAutocompleteItems = () =>
    wrapper.findComponent(GlobalSearchAutocompleteItems);
  const findSearchInputDescription = () => wrapper.find(`#${SEARCH_INPUT_DESCRIPTION}`);
  const findSearchResultsDescription = () => wrapper.findByTestId(SEARCH_RESULTS_DESCRIPTION);
  const findCommandPaletteItems = () => wrapper.findComponent(CommandPaletteItems);
  const findFakeSearchInput = () => wrapper.findComponent(FakeSearchInput);

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
        search         | hasToken
        ${MOCK_SEARCH} | ${true}
        ${'te'}        | ${false}
        ${'x'}         | ${false}
        ${''}          | ${false}
      `('token', ({ search, hasToken }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent({ search });
          findGlobalSearchInput().vm.$emit('click');
        });

        it(`${hasToken ? 'is' : 'is NOT'} rendered when search query is "${search}"`, () => {
          expect(findScopeToken().exists()).toBe(hasToken);
        });
      });

      describe.each(MOCK_SCOPED_SEARCH_OPTIONS)('token content', (searchOption) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent(
            { search: MOCK_SEARCH },
            {
              searchOptions: () => [searchOption],
            },
          );
          findGlobalSearchInput().vm.$emit('click');
        });

        it(`is correctly rendered`, () => {
          if (searchOption.scope) {
            expect(findScopeToken().text()).toBe(formatScopeName(searchOption.scope));
          } else {
            expect(findScopeToken().text()).toBe(formatScopeName(searchOption.description));
          }
        });
      });

      describe.each`
        searchOptions                      | iconName
        ${[MOCK_SCOPED_SEARCH_OPTIONS[0]]} | ${ICON_PROJECT}
        ${[MOCK_SCOPED_SEARCH_OPTIONS[2]]} | ${ICON_GROUP}
        ${[MOCK_SCOPED_SEARCH_OPTIONS[3]]} | ${ICON_SUBGROUP}
        ${[MOCK_SCOPED_SEARCH_OPTIONS[4]]} | ${false}
      `('token', ({ searchOptions, iconName }) => {
        beforeEach(() => {
          window.gon.current_username = MOCK_USERNAME;
          createComponent(
            { search: MOCK_SEARCH },
            {
              searchOptions: () => searchOptions,
            },
          );
          findGlobalSearchInput().vm.$emit('click');
        });

        it(`renders ${iconName ? `"${iconName}"` : 'NO'} icon for "${
          searchOptions[0]?.text
        }" scope`, () => {
          expect(
            findScopeToken().findComponent(GlIcon).exists() &&
              findScopeToken().findComponent(GlIcon).attributes('name'),
          ).toBe(iconName);
        });
      });
    });

    describe('Command palette', () => {
      describe('when FF `command_palette` is disabled', () => {
        beforeEach(() => {
          createComponent();
        });

        it('should not render command mode components', () => {
          expect(findCommandPaletteItems().exists()).toBe(false);
          expect(findFakeSearchInput().exists()).toBe(false);
        });

        it('should provide default placeholder to the search input', () => {
          expect(findGlobalSearchInput().attributes('placeholder')).toBe(SEARCH_GITLAB);
        });
      });

      describe.each([...COMMON_HANDLES, PATH_HANDLE])(
        'when FF `command_palette` is enabled and search handle is %s',
        (handle) => {
          beforeEach(() => {
            createComponent({ search: handle }, undefined, undefined, {
              commandPalette: true,
            });
          });

          it('should render command mode components', () => {
            expect(findCommandPaletteItems().exists()).toBe(true);
            expect(findFakeSearchInput().exists()).toBe(true);
          });

          it('should provide an alternative placeholder to the search input', () => {
            expect(findGlobalSearchInput().attributes('placeholder')).toBe(
              SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
            );
          });

          it('should not render the scope token', () => {
            expect(findScopeToken().exists()).toBe(false);
          });
        },
      );
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
        const submitSearch = () =>
          findGlobalSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        describe('in command mode', () => {
          beforeEach(() => {
            createComponent({ search: '>' }, undefined, undefined, {
              commandPalette: true,
            });
            submitSearch();
          });

          it('does not submit a search', () => {
            expect(visitUrl).not.toHaveBeenCalled();
          });
        });

        describe('in search mode', () => {
          it('will NOT submit a search with less than min characters', () => {
            createComponent({ search: 'x' });
            submitSearch();
            expect(visitUrl).not.toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
          });

          it('will submit a search with the sufficient number of characters', () => {
            createComponent();
            submitSearch();
            expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
          });
        });
      });
    });

    describe('Modal events', () => {
      beforeEach(() => {
        createComponent({ search: 'searchQuery' });
      });

      it('should emit `shown` event when modal shown`', () => {
        findGlobalSearchModal().vm.$emit('shown');
        expect(wrapper.emitted('shown')).toHaveLength(1);
      });

      it('should emit `hidden` event when modal hidden and clear the search input', () => {
        findGlobalSearchModal().vm.$emit('hide');
        expect(wrapper.emitted('hidden')).toHaveLength(1);
        expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), '');
      });
    });
  });
});
