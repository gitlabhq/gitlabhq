import { GlModal, GlSearchBoxByType } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { Mousetrap } from '~/lib/mousetrap';
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
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  COMMON_HANDLES,
  COMMAND_HANDLE,
  USER_HANDLE,
  PROJECT_HANDLE,
  PATH_HANDLE,
  MODAL_CLOSE_ESC,
  MODAL_CLOSE_BACKGROUND,
  MODAL_CLOSE_HEADERCLOSE,
  COMMANDS_TOGGLE_KEYBINDING,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  KEY_N,
  KEY_P,
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
  queryToObject: jest.fn(),
  objectToQuery: jest.fn(() => 'search=test'),
  isRootRelative: jest.fn(),
  getBaseURL: jest.fn(() => 'https://gdk.test:3000'),
}));

jest.mock('~/search/store/utils.js', () => ({
  injectRegexSearch: jest.fn(() => '/search?search=test'),
}));

// eslint-disable-next-line max-params
const triggerKeydownEvent = (target, code, metaKey = false, ctrlKey = false) => {
  const event = new KeyboardEvent('keydown', {
    bubbles: true,
    cancelable: true,
    code,
    metaKey,
    ctrlKey,
  });
  target.dispatchEvent(event);
  return event;
};

describe('GlobalSearchModal', () => {
  let wrapper;
  let store;
  let handleClosingSpy;
  let onKeyComboDownSpy;

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
    store = new Vuex.Store({
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

  beforeEach(() => {
    handleClosingSpy = jest.spyOn(GlobalSearchModal.methods, 'handleClosing');
    onKeyComboDownSpy = jest.spyOn(GlobalSearchModal.methods, 'onKeyComboToggleDropdown');
  });

  afterEach(() => {
    handleClosingSpy.mockRestore();
    onKeyComboDownSpy.mockRestore();
  });

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
  const findCommandPaletteInput = () =>
    findGlobalSearchInput().find('[data-testid="search-input-field"]');

  describe('template', () => {
    beforeEach(() => {
      useMockLocationHelper();
    });
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

    describe('when using command palette', () => {
      const possibleHandles = [...COMMON_HANDLES];

      describe.each(possibleHandles)('when search handle is "%s"', (handle) => {
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
          expect(findGlobalSearchInput().attributes('placeholder')).toBe('Type to search...');
        });
      });

      describe.each(possibleHandles)('when search handle is "%s"', (handle) => {
        beforeEach(() => {
          createComponent({
            initialState: { search: '', commandChar: handle },
            mockGetters: {
              ...defaultMockGetters,
              isCommandMode: () => Boolean(handle),
            },
            stubs: {
              GlModal,
              GlSearchBoxByType: {
                props: {
                  value: {
                    type: String,
                    default: '',
                  },
                },
                template: `
                  <div>
                    <input
                      :value="value"
                      ref="input"
                      v-bind="$attrs"
                      v-on="$listeners"
                      data-testid="search-input-field"
                      @input="$emit('input', $event.target.value)"
                    />
                  </div>
                `,
              },
            },
            attachTo: document.body,
          });

          findGlobalSearchInput().vm.$emit('click');
        });

        it('should handle command selection', async () => {
          await findCommandPaletteDropdown().vm.$emit('selected', handle);

          expect(actionSpies.setCommand).toHaveBeenCalledWith(expect.any(Object), handle);
        });

        it('should focus search input', async () => {
          await findCommandPaletteDropdown().vm.$emit('selected', handle);
          await nextTick();
          expect(document.activeElement).toBe(findCommandPaletteInput().element);
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
            new KeyboardEvent('keydown', { code: ENTER_KEY }),
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
          let getFocusableOptionsSpy;

          beforeEach(() => {
            getFocusableOptionsSpy = jest.spyOn(GlobalSearchModal.methods, 'getFocusableOptions');
            getFocusableOptionsSpy.mockReturnValue([
              document.createElement('li'),
              document.createElement('li'),
            ]);
          });

          afterEach(() => {
            getFocusableOptionsSpy.mockRestore();
          });

          it('will NOT submit a search with less than min characters', () => {
            createComponent({ initialState: { search: 'x' } });
            submitSearch();
            expect(visitUrl).not.toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
          });

          it('will submit a search with the sufficient number of characters', () => {
            createComponent();
            findGlobalSearchInput().vm.$emit('input', MOCK_SEARCH);

            submitSearch();
            expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
          });
        });
      });
    });

    describe('Modal events', () => {
      beforeEach(() => {
        createComponent({
          initialState: { search: '', commandChar: '' },
          mockGetters: {
            ...defaultMockGetters,
            isCommandMode: () => Boolean(''),
          },
          stubs: {
            GlModal,
            GlSearchBoxByType,
            GlobalSearchDefaultItems,
          },
        });
      });

      describe('when combination shortcut is pressed', () => {
        it('calls handleClosing when hidden event is emitted', () => {
          findCommandPaletteDropdown().vm.$emit('hidden');
          expect(handleClosingSpy).toHaveBeenCalled();
        });

        it('key combination triggers correctly', async () => {
          const openSpy = jest.fn();
          const closeSpy = jest.fn();

          wrapper.vm.$refs.commandDropdown.open = openSpy;
          wrapper.vm.$refs.commandDropdown.close = closeSpy;

          await findGlobalSearchModal().vm.$emit('shown');

          Mousetrap.trigger(COMMANDS_TOGGLE_KEYBINDING);
          Mousetrap.trigger(COMMANDS_TOGGLE_KEYBINDING);

          expect(openSpy).toHaveBeenCalledTimes(1);
          expect(closeSpy).toHaveBeenCalledTimes(1);
        });

        it('opens correctly after esc dismiss of open dropdown', async () => {
          const openSpy = jest.fn();
          const closeSpy = jest.fn();

          wrapper.vm.$refs.commandDropdown.open = openSpy;
          wrapper.vm.$refs.commandDropdown.close = closeSpy;

          await findGlobalSearchModal().vm.$emit('shown');
          Mousetrap.trigger(COMMANDS_TOGGLE_KEYBINDING);
          findCommandPaletteDropdown().vm.$emit('hidden');
          Mousetrap.trigger(COMMANDS_TOGGLE_KEYBINDING);

          expect(openSpy).toHaveBeenCalledTimes(2);
          expect(closeSpy).toHaveBeenCalledTimes(0);
        });
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

  describe('Track events', () => {
    let getFocusableOptionsSpy;

    beforeEach(() => {
      getFocusableOptionsSpy = jest.spyOn(GlobalSearchModal.methods, 'getFocusableOptions');
      getFocusableOptionsSpy.mockReturnValue([
        document.createElement('li'),
        document.createElement('li'),
      ]);

      createComponent({
        initialState: { search: '', commandChar: '' },
        mockGetters: {
          ...defaultMockGetters,
          isCommandMode: () => Boolean(''),
        },
        stubs: {
          GlModal,
          GlSearchBoxByType,
        },
      });
    });

    afterEach(() => {
      getFocusableOptionsSpy.mockRestore();
    });

    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it.each`
      dropdownEvent     | trackingEvent
      ${COMMAND_HANDLE} | ${'press_greater_than_in_command_palette'}
      ${USER_HANDLE}    | ${'press_at_symbol_in_command_palette'}
      ${PROJECT_HANDLE} | ${'press_colon_in_command_palette'}
      ${PATH_HANDLE}    | ${'press_forward_slash_in_command_palette'}
    `('triggers and tracks command dropdown $dropdownEvent', ({ dropdownEvent, trackingEvent }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findCommandPaletteDropdown().vm.$emit('selected', dropdownEvent);

      expect(trackEventSpy).toHaveBeenCalledWith(trackingEvent, {}, undefined);
    });

    it.each`
      modalEvent                 | trackingEvent
      ${MODAL_CLOSE_ESC}         | ${'press_escape_in_command_palette'}
      ${MODAL_CLOSE_BACKGROUND}  | ${'click_outside_of_command_palette'}
      ${MODAL_CLOSE_HEADERCLOSE} | ${'press_escape_in_command_palette'}
    `('triggers and tracks modal event $modalEvent', async ({ modalEvent, trackingEvent }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findGlobalSearchModal().vm.$emit('hide', { trigger: modalEvent });

      expect(trackEventSpy).toHaveBeenCalledWith(trackingEvent, {}, undefined);
    });

    it('triggers and tracks key event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const event = {
        code: ENTER_KEY,
        target: '',
        stopPropagation: jest.fn(),
        preventDefault: jest.fn(),
      };

      findGlobalSearchInput().vm.$emit('keydown', event);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'press_enter_to_advanced_search',
        { label: 'command_palette' },
        undefined,
      );
    });
  });

  describe('Navigating results', () => {
    const findSearchInput = () => wrapper.findByRole('searchbox');

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
      let getFocusableOptionsSpy;
      let submitSearchSpy;
      let dispatchEventSpy;

      beforeEach(() => {
        getFocusableOptionsSpy = jest.spyOn(GlobalSearchModal.methods, 'getFocusableOptions');
        submitSearchSpy = jest.spyOn(GlobalSearchModal.methods, 'submitSearch');
        dispatchEventSpy = jest.spyOn(
          wrapper.findByTestId('test-result-2').element,
          'dispatchEvent',
        );

        getFocusableOptionsSpy.mockReturnValue([
          document.createElement('li'),
          document.createElement('li'),
        ]);

        wrapper.findByTestId('test-result-2').element.focus();
      });

      afterEach(() => {
        getFocusableOptionsSpy.mockRestore();
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
        triggerKeydownEvent(document.activeElement, NUMPAD_ENTER_KEY);
        expect(submitSearchSpy).not.toHaveBeenCalled();
        expect(dispatchEventSpy).toHaveBeenCalled();
      });
    });

    describe('when navigating using keyboard shortcuts', () => {
      beforeEach(async () => {
        await findGlobalSearchModal().vm.$emit('shown');
        findSearchInput().element.focus();
      });

      it('should focus the next item when Ctrl+N is pressed', () => {
        findSearchInput().trigger('keydown', { code: KEY_N, ctrlKey: true });

        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
      });

      it('should focus the previous item when Ctrl+P is pressed', () => {
        findSearchInput().trigger('keydown', { code: KEY_N, ctrlKey: true });
        findSearchInput().trigger('keydown', { code: KEY_N, ctrlKey: true });

        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-2').element);

        findSearchInput().trigger('keydown', { code: KEY_P, ctrlKey: true });

        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
      });

      it('should wrap to the last item when Ctrl+P is pressed at the first item', () => {
        findSearchInput().trigger('keydown', { code: KEY_P, ctrlKey: true });
        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-5').element);
      });

      it('should wrap to the first item when Ctrl+N is pressed at the last item', async () => {
        // triggers getListItemsAndFocusIndex() to grab the result items
        findSearchInput().trigger('keydown', { code: '', ctrlKey: true });
        await nextTick();

        const lastIndex = wrapper.vm.childListItems.length - 1;

        wrapper.vm.focusIndex = lastIndex;
        wrapper.vm.childListItems[lastIndex].focus();

        findSearchInput().trigger('keydown', { code: KEY_N, ctrlKey: true });

        expect(document.activeElement).toBe(wrapper.findByTestId('test-result-1').element);
      });
    });
  });
});
