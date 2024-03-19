import { GlModal, GlSearchBoxByType } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import GlobalSearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import GlobalSearchAutocompleteItems from '~/super_sidebar/components/global_search/components/global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import GlobalSearchScopedItems from '~/super_sidebar/components/global_search/components/global_search_scoped_items.vue';
import FakeSearchInput from '~/super_sidebar/components/global_search/command_palette/fake_search_input.vue';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import CommandsOverviewDropdown from '~/super_sidebar/components/global_search/command_palette/command_overview_dropdown.vue';
import ScrollScrim from '~/super_sidebar/components/scroll_scrim.vue';
import {
  SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
  COMMON_HANDLES,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
} from '~/super_sidebar/components/global_search/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  ENTER_KEY,
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  END_KEY,
  HOME_KEY,
  NUMPAD_ENTER_KEY,
} from '~/lib/utils/keys';
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
    setCommand: jest.fn(),
    fetchAutocompleteOptions: jest.fn(),
    clearAutocomplete: jest.fn(),
  };

  const defaultMockState = {
    searchContext: {
      project: MOCK_PROJECT,
      group: MOCK_GROUP,
    },
    commandChar: '',
  };

  const defaultMockGetters = {
    searchQuery: () => MOCK_SEARCH_QUERY,
    searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
    scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
    isCommandMode: () => false,
  };

  const createComponent = ({
    initialState = defaultMockState,
    mockGetters = defaultMockGetters,
    stubs,
    ...mountOptions
  } = {}) => {
    const store = new Vuex.Store({
      state: {
        ...defaultMockState,
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
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
      stubs,
      ...mountOptions,
    });
  };

  const findGlobalSearchModal = () => wrapper.findComponent(GlModal);

  const findGlobalSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findGlobalSearchDefaultItems = () => wrapper.findComponent(GlobalSearchDefaultItems);
  const findGlobalSearchScopedItems = () => wrapper.findComponent(GlobalSearchScopedItems);
  const findGlobalSearchAutocompleteItems = () =>
    wrapper.findComponent(GlobalSearchAutocompleteItems);
  const findSearchInputDescription = () => wrapper.find(`#${SEARCH_INPUT_DESCRIPTION}`);
  const findSearchResultsDescription = () => wrapper.findByTestId(SEARCH_RESULTS_DESCRIPTION);
  const findCommandPaletteItems = () => wrapper.findComponent(CommandPaletteItems);
  const findFakeSearchInput = () => wrapper.findComponent(FakeSearchInput);
  const findScrollScrim = () => wrapper.findComponent(ScrollScrim);
  const findCommandPaletteDropdown = () => wrapper.findComponent(CommandsOverviewDropdown);

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
      it('renders the ScrollScrim component', () => {
        expect(findScrollScrim().exists()).toBe(true);
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
          createComponent({ initialState: { search } });
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
            createComponent({
              initialState: {
                search,
                loading,
              },
              mockGetters: {
                ...defaultMockGetters,
                searchOptions: () => searchOptions,
              },
            });
          });

          it(`sets description to ${expectedDesc}`, () => {
            expect(findSearchResultsDescription().text()).toBe(expectedDesc);
          });
        });
      },
    );

    describe('Command palette', () => {
      const possibleHandles = ['', ...COMMON_HANDLES];

      describe.each(possibleHandles)('when search handle is %s', (handle) => {
        beforeEach(() => {
          createComponent({
            initialState: { search: handle, commandChar: handle },
            mockGetters: {
              ...defaultMockGetters,
              isCommandMode: () => Boolean(handle),
            },
          });
        });

        it('should render command mode components', () => {
          expect(findCommandPaletteItems().exists()).toBe(Boolean(handle));
          expect(findFakeSearchInput().exists()).toBe(Boolean(handle));
        });

        it('should provide an alternative placeholder to the search input', () => {
          expect(findGlobalSearchInput().attributes('placeholder')).toBe(
            SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
          );
        });
      });

      describe.each(possibleHandles)('when search handle is %s', (handle) => {
        beforeEach(() => {
          createComponent({
            initialState: { search: '', commandChar: handle },
            mockGetters: {
              ...defaultMockGetters,
              isCommandMode: () => Boolean(handle),
            },
            stubs: {
              GlModal,
              GlSearchBoxByType,
            },
          });

          findGlobalSearchInput().vm.$emit('click');
        });

        it.each(possibleHandles)('should handle command selection', async (selected) => {
          await findCommandPaletteDropdown().vm.$emit('selected', selected);

          expect(actionSpies.setCommand).toHaveBeenCalledWith(expect.any(Object), selected);
        });
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

          it('calls setCommand with search term', () => {
            expect(actionSpies.setCommand).toHaveBeenCalledWith(expect.any(Object), '');
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
          findGlobalSearchInput().vm.$emit(
            'keydown',
            new KeyboardEvent('keydown', { key: ENTER_KEY }),
          );

        describe.each`
          firstInputText | secondInputText | outputText | command | secondCommand
          ${''}          | ${'test'}       | ${'test'}  | ${''}   | ${''}
          ${''}          | ${'>test'}      | ${'>test'} | ${''}   | ${'>'}
          ${'>test'}     | ${'>test'}      | ${'>test'} | ${'>'}  | ${'>'}
          ${'>test'}     | ${'~test'}      | ${'~test'} | ${'>'}  | ${'~'}
          ${''}          | ${'~~~~'}       | ${'~~~~'}  | ${''}   | ${'~'}
        `(
          'in command mode',
          ({ firstInputText, secondInputText, outputText, command, secondCommand }) => {
            beforeEach(() => {
              createComponent({
                initialState: { search: firstInputText, commandChar: command },
                mockGetters: {
                  ...defaultMockGetters,
                  isCommandMode: () => Boolean(command),
                },
              });

              submitSearch();
            });

            afterEach(() => {
              jest.clearAllMocks();
            });

            it('does not submit a search', () => {
              expect(visitUrl).not.toHaveBeenCalled();
            });

            it('update search input recognizes correct input', () => {
              findGlobalSearchInput().vm.$emit('input', secondInputText);
              expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), outputText);
              expect(actionSpies.setCommand).toHaveBeenCalledWith(
                expect.any(Object),
                secondCommand,
              );
            });
          },
        );

        describe('in search mode', () => {
          it('will NOT submit a search with less than min characters', () => {
            createComponent({ initialState: { search: 'x' } });
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
        createComponent({ initialState: { search: 'searchQuery' } });
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

  describe('Navigating results', () => {
    const findSearchInput = () => wrapper.findByRole('searchbox');
    const triggerKeydownEvent = (target, code) => {
      const event = new KeyboardEvent('keydown', { bubbles: true, cancelable: true, code });
      target.dispatchEvent(event);
      return event;
    };

    beforeEach(() => {
      createComponent({
        stubs: {
          GlSearchBoxByType: {
            inheritAttrs: false,
            template: '<div><input v-bind="$attrs" v-on="$listeners"></div>',
          },
          GlobalSearchDefaultItems: {
            template: `
              <ul>
                <li
                  v-for="n in 5"
                  class="gl-new-dropdown-item"
                  tabindex="0"
                  :data-testid="'test-result-' + n"
                ><a href="#">Result {{ n }}</a></li>
              </ul>`,
          },
        },
        attachTo: document.body,
      });
    });

    describe('when the search input has focus', () => {
      beforeEach(() => {
        findSearchInput().element.focus();
      });

      it('Home key keeps focus in input', () => {
        const event = triggerKeydownEvent(findSearchInput().element, HOME_KEY);
        expect(document.activeElement).toBe(findSearchInput().element);
        expect(event.defaultPrevented).toBe(false);
      });

      it('End key keeps focus on input', () => {
        const event = triggerKeydownEvent(findSearchInput().element, END_KEY);
        findSearchInput().trigger('keydown', { code: END_KEY });
        expect(document.activeElement).toBe(findSearchInput().element);
        expect(event.defaultPrevented).toBe(false);
      });

      it('ArrowUp keeps focus on input', () => {
        const event = triggerKeydownEvent(findSearchInput().element, ARROW_UP_KEY);
        expect(document.activeElement).toBe(findSearchInput().element);
        expect(event.defaultPrevented).toBe(false);
      });

      it('ArrowDown focuses the first item', () => {
        const event = triggerKeydownEvent(findSearchInput().element, ARROW_DOWN_KEY);
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
        expect(event.defaultPrevented).toBe(true);
      });
    });

    describe('when search result item has focus', () => {
      beforeEach(() => {
        wrapper.findByTestId('test-result-2').element.focus();
      });

      it('Home key focuses first item', () => {
        const event = triggerKeydownEvent(document.activeElement, HOME_KEY);
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
        expect(event.defaultPrevented).toBe(true);
      });

      it('End key focuses last item', () => {
        const event = triggerKeydownEvent(document.activeElement, END_KEY);
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-5').element);
        expect(event.defaultPrevented).toBe(true);
      });

      it('ArrowUp focuses previous item if any, else input', () => {
        let event = triggerKeydownEvent(document.activeElement, ARROW_UP_KEY);
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
        expect(event.defaultPrevented).toBe(true);

        event = triggerKeydownEvent(document.activeElement, ARROW_UP_KEY);
        expect(document.activeElement).toBe(findSearchInput().element);
        expect(event.defaultPrevented).toBe(true);
      });

      it('ArrowDown focuses next item', () => {
        const event = triggerKeydownEvent(document.activeElement, ARROW_DOWN_KEY);
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-3').element);
        expect(event.defaultPrevented).toBe(true);
      });

      it('NumpadEnter clicks the current item child', () => {
        const focusedElement = document.activeElement;
        const focusedElementChild = focusedElement.firstChild;

        const clickMock = jest.fn();
        focusedElementChild.click = clickMock;

        const event = triggerKeydownEvent(focusedElement, NUMPAD_ENTER_KEY);
        expect(clickMock).toHaveBeenCalled();
        expect(event.defaultPrevented).toBe(true);
      });
    });
  });
});
