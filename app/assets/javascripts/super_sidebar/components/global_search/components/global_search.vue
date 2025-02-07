<script>
import { GlSearchBoxByType, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce, clamp } from 'lodash';
import { InternalEvents } from '~/tracking';
import { Mousetrap, addStopCallback } from '~/lib/mousetrap';
import { visitUrl } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, sprintf } from '~/locale';
import {
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  END_KEY,
  HOME_KEY,
  ESC_KEY,
  NUMPAD_ENTER_KEY,
  ENTER_KEY,
} from '~/lib/utils/keys';
import {
  COMMAND_PALETTE,
  MIN_SEARCH_TERM,
  SEARCH_DESCRIBED_BY_WITH_RESULTS,
  SEARCH_DESCRIBED_BY_DEFAULT,
  SEARCH_DESCRIBED_BY_UPDATED,
  SEARCH_RESULTS_LOADING,
  COMMAND_PALETTE_TIP,
} from '~/vue_shared/global_search/constants';
import modalKeyboardNavigationMixin from '~/vue_shared/mixins/modal_keyboard_navigation_mixin';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import ScrollScrim from '~/super_sidebar/components/scroll_scrim.vue';
import { injectRegexSearch } from '~/search/store/utils';
import {
  EVENT_PRESS_ENTER_TO_ADVANCED_SEARCH,
  EVENT_PRESS_ESCAPE_IN_COMMAND_PALETTE,
  EVENT_CLICK_OUTSIDE_OF_COMMAND_PALETTE,
  EVENT_PRESS_GREATER_THAN_IN_COMMAND_PALETTE,
  EVENT_PRESS_AT_SYMBOL_IN_COMMAND_PALETTE,
  EVENT_PRESS_COLON_IN_COMMAND_PALETTE,
  EVENT_PRESS_FORWARD_SLASH_IN_COMMAND_PALETTE,
  LABEL_COMMAND_PALETTE,
} from '~/super_sidebar/tracking_constants';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SEARCH_MODAL_ID,
  KEY_N,
  KEY_P,
  SEARCH_INPUT_SELECTOR,
  SEARCH_RESULTS_ITEM_SELECTOR,
} from '../constants';
import CommandPaletteItems from '../command_palette/command_palette_items.vue';
import FakeSearchInput from '../command_palette/fake_search_input.vue';
import {
  COMMON_HANDLES,
  COMMAND_HANDLE,
  USER_HANDLE,
  PROJECT_HANDLE,
  ISSUE_HANDLE,
  PATH_HANDLE,
  MODAL_CLOSE_ESC,
  MODAL_CLOSE_BACKGROUND,
  MODAL_CLOSE_HEADERCLOSE,
  COMMANDS_TOGGLE_KEYBINDING,
} from '../command_palette/constants';
import CommandPaletteLottery from '../command_palette/command_palette_lottery.vue';
import CommandsOverviewDropdown from '../command_palette/command_overview_dropdown.vue';
import { commandPaletteDropdownItems } from '../utils';
import GlobalSearchAutocompleteItems from './global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from './global_search_default_items.vue';
import GlobalSearchScopedItems from './global_search_scoped_items.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GlobalSearchModal',
  SEARCH_MODAL_ID,
  i18n: {
    COMMAND_PALETTE,
    SEARCH_DESCRIBED_BY_WITH_RESULTS,
    SEARCH_DESCRIBED_BY_DEFAULT,
    SEARCH_DESCRIBED_BY_UPDATED,
    SEARCH_OR_COMMAND_MODE_PLACEHOLDER: s__('GlobalSearch|Type to search...'),
    SEARCH_RESULTS_LOADING,
    MIN_SEARCH_TERM,
    COMMAND_PALETTE_TIP,
    COMMON_HANDLES,
  },
  components: {
    GlSearchBoxByType,
    GlobalSearchDefaultItems,
    GlobalSearchScopedItems,
    GlobalSearchAutocompleteItems,
    GlModal,
    CommandPaletteItems,
    FakeSearchInput,
    CommandPaletteLottery,
    ScrollScrim,
    CommandsOverviewDropdown,
  },
  mixins: [trackingMixin, modalKeyboardNavigationMixin],
  data() {
    return {
      nextFocusedItemIndex: null,
      commandPaletteDropdownItems,
      commandPaletteDropdownOpen: false,
      focusIndex: -1,
      childListItems: [],
    };
  },
  computed: {
    ...mapState(['search', 'loading', 'searchContext', 'commandChar']),
    ...mapGetters(['searchQuery', 'searchOptions', 'scopedSearchOptions', 'isCommandMode']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        if (this.stringHasCommand(value)) {
          this.setCommand(this.stringFirstChar(value));
          this.setSearch(value);
          return;
        }

        this.setCommand('');
        this.setSearch(value);
      },
    },
    showDefaultItems() {
      return !this.searchText;
    },
    searchTermOverMin() {
      return this.searchText?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;
    },
    showScopedSearchItems() {
      return this.searchTermOverMin && this.scopedSearchOptions.length > 0;
    },
    searchResultsDescription() {
      if (this.showDefaultItems) {
        return sprintf(this.$options.i18n.SEARCH_DESCRIBED_BY_DEFAULT, {
          count: this.searchOptions.length,
        });
      }

      if (!this.searchTermOverMin) {
        return this.$options.i18n.MIN_SEARCH_TERM;
      }

      return this.loading
        ? this.$options.i18n.SEARCH_RESULTS_LOADING
        : sprintf(this.$options.i18n.SEARCH_DESCRIBED_BY_UPDATED, {
            count: this.searchOptions.length,
          });
    },
    searchBarItem() {
      return this.searchOptions?.[0];
    },
    commandPaletteQuery() {
      if (this.isCommandMode) {
        return this.searchText?.trim().substring(1);
      }
      return '';
    },
    commandHighlightClass() {
      return darkModeEnabled() ? '!gl-bg-subtle' : '!gl-bg-strong';
    },
  },
  watch: {
    nextFocusedItemIndex() {
      this.highlightFirstCommand();
    },
  },
  created() {
    addStopCallback(this.allowMousetrapBindingOnSearchInput);
  },
  methods: {
    ...mapActions(['setSearch', 'setCommand', 'fetchAutocompleteOptions', 'clearAutocomplete']),
    getAutocompleteOptions: debounce(function debouncedSearch(searchTerm) {
      if (this.isCommandMode) {
        return;
      }
      if (!searchTerm) {
        this.clearAutocomplete();
      } else {
        this.fetchAutocompleteOptions();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    getFocusableOptions() {
      return Array.from(
        this.$refs.resultsList?.querySelectorAll(SEARCH_RESULTS_ITEM_SELECTOR) || [],
      );
    },
    handleSubmitSearch(event) {
      this.submitSearch();
      event.stopPropagation();
      event.preventDefault();
    },
    getListItemsAndFocusIndex() {
      const childItems = this.$refs.resultsList?.querySelectorAll('.gl-new-dropdown-item') || [];
      if (childItems.length !== this.childListItems.length) {
        this.childListItems = childItems;

        Array.from(childItems).forEach((item, index) => {
          if (item === document.activeElement) {
            this.focusIndex = index;
          }
        });
      }
    },
    onKeydown(event) {
      const { code, ctrlKey, target } = event;

      let stop = true;
      const isSearchInput = target && target?.matches(SEARCH_INPUT_SELECTOR);
      const elements = this.getFocusableOptions();
      this.getListItemsAndFocusIndex();

      switch (code) {
        case ENTER_KEY:
        case NUMPAD_ENTER_KEY:
          // we want to submit search term specifically if isSearchInput
          // we want to submit search term if there are no results (elements.length < 1)
          this.trackEvent(EVENT_PRESS_ENTER_TO_ADVANCED_SEARCH, { label: LABEL_COMMAND_PALETTE });
          this.handleSubmitSearch(event);
          break;

        case HOME_KEY:
          if (isSearchInput) return;
          if (elements.length < 1) return;

          this.focusItem(0, elements);
          break;

        case END_KEY:
          if (isSearchInput) return;
          if (elements.length < 1) return;

          this.focusItem(elements.length - 1, elements);
          break;

        case ARROW_UP_KEY:
          if (isSearchInput) return;
          if (elements.length < 1) return;

          if (elements.indexOf(target) === 0) {
            this.focusSearchInput();
          } else {
            this.focusNextItem(event, elements, -1);
          }
          break;

        case ARROW_DOWN_KEY:
          if (elements.length < 1) return;
          this.focusNextItem(event, elements, 1);
          break;

        case KEY_P:
          if (!ctrlKey) {
            return;
          }

          this.focusIndex =
            this.focusIndex > 0 ? this.focusIndex - 1 : this.childListItems.length - 1;
          this.childListItems[this.focusIndex]?.focus();
          break;

        case KEY_N:
          if (!ctrlKey) {
            return;
          }

          this.focusIndex =
            this.focusIndex < this.childListItems.length - 1 ? this.focusIndex + 1 : 0;
          this.childListItems[this.focusIndex]?.focus();
          break;

        case ESC_KEY:
          this.$refs.modal.close();
          break;

        default:
          stop = false;
          break;
      }

      if (stop) {
        event.preventDefault();
      }
    },
    onKeyComboToggleDropdown(event) {
      if (event.preventDefault) {
        event.preventDefault();
      }

      if (!this.commandPaletteDropdownOpen) {
        this.$refs.commandDropdown.open();
        this.commandPaletteDropdownOpen = true;
      } else {
        this.$refs.commandDropdown.close();
        this.commandPaletteDropdownOpen = false;
      }
    },
    allowMousetrapBindingOnSearchInput(event, element, combo) {
      if (combo !== COMMANDS_TOGGLE_KEYBINDING) {
        return undefined;
      }

      const search = this.$refs.searchInput.$el;
      if (search?.contains(element)) {
        return false;
      }

      return undefined;
    },
    handleClosing() {
      this.commandPaletteDropdownOpen = false;
    },
    focusSearchInput() {
      this.$refs?.searchInput?.$el?.querySelector('input')?.focus();
    },
    focusNextItem(event, elements, offset) {
      const { target } = event;
      const currentIndex = elements.indexOf(target);
      const nextIndex = clamp(currentIndex + offset, 0, elements.length - 1);

      this.focusItem(nextIndex, elements);
    },
    focusItem(index, elements) {
      this.nextFocusedItemIndex = index;
      elements[index]?.focus();
    },
    submitSearch() {
      if (this.isCommandMode) {
        this.runFirstCommand();
        return;
      }
      if (this.search?.length <= SEARCH_SHORTCUTS_MIN_CHARACTERS) {
        return;
      }

      visitUrl(injectRegexSearch(this.searchQuery));
    },
    runFirstCommand() {
      this.getFocusableOptions()[0]?.firstChild?.click();
    },
    onSearchModalShown() {
      this.$emit('shown');

      Mousetrap.bind(COMMANDS_TOGGLE_KEYBINDING, this.onKeyComboToggleDropdown);
    },
    onSearchModalHidden({ trigger } = {}) {
      this.searchText = '';
      this.$emit('hidden');

      Mousetrap.unbind(COMMANDS_TOGGLE_KEYBINDING);

      switch (trigger) {
        case this.$options.MODAL_CLOSE_ESC:
        case this.$options.MODAL_CLOSE_HEADERCLOSE: {
          // when esc is pressed with focus
          // in the input field modal issues headerclose
          this.trackEvent(EVENT_PRESS_ESCAPE_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.MODAL_CLOSE_BACKGROUND: {
          this.trackEvent(EVENT_CLICK_OUTSIDE_OF_COMMAND_PALETTE);
          break;
        }
        default: {
          /* empty */
        }
      }
    },
    highlightFirstCommand() {
      if (this.isCommandMode) {
        const activeCommand = this.getFocusableOptions()[0]?.firstChild;
        activeCommand?.classList.toggle(
          this.commandHighlightClass,
          Boolean(!this.nextFocusedItemIndex),
        );
      }
    },
    handleCommandSelection(selected) {
      this.searchText = this.stringHasCommand(this.searchText)
        ? `${selected}${this.searchText.slice(1)}`
        : `${selected}${this.searchText}`;

      this.focusSearchInput();

      switch (selected) {
        case this.$options.COMMAND_HANDLE: {
          this.trackEvent(EVENT_PRESS_GREATER_THAN_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.USER_HANDLE: {
          this.trackEvent(EVENT_PRESS_AT_SYMBOL_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.PROJECT_HANDLE: {
          this.trackEvent(EVENT_PRESS_COLON_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.PATH_HANDLE: {
          this.trackEvent(EVENT_PRESS_FORWARD_SLASH_IN_COMMAND_PALETTE);
          break;
        }
        default: {
          /* empty */
        }
      }
    },
    stringHasCommand(string) {
      const isHandle = (handle) => handle === string?.trim().charAt(0);

      return (
        COMMON_HANDLES.some(isHandle) ||
        (this.searchContext?.project && COMMON_HANDLES.some(isHandle))
      );
    },
    stringFirstChar(string) {
      return string?.trim().charAt(0);
    },
  },
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  COMMAND_HANDLE,
  USER_HANDLE,
  PROJECT_HANDLE,
  ISSUE_HANDLE,
  PATH_HANDLE,
  MODAL_CLOSE_ESC,
  MODAL_CLOSE_BACKGROUND,
  MODAL_CLOSE_HEADERCLOSE,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.SEARCH_MODAL_ID"
    hide-header
    hide-header-close
    scrollable
    :title="$options.i18n.COMMAND_PALETTE"
    body-class="!gl-p-0 !gl-min-h-26"
    modal-class="global-search-modal"
    :centered="false"
    @shown="onSearchModalShown"
    @hide="onSearchModalHidden"
  >
    <form
      role="search"
      :aria-label="$options.i18n.SEARCH_OR_COMMAND_MODE_PLACEHOLDER"
      class="gl-relative gl-w-full gl-rounded-lg gl-pb-0"
    >
      <div class="input-box-wrapper gl-border-b -gl-mb-1 gl-bg-default gl-p-2">
        <gl-search-box-by-type
          id="search"
          ref="searchInput"
          v-model="searchText"
          role="searchbox"
          data-testid="global-search-input"
          autocomplete="off"
          :placeholder="$options.i18n.SEARCH_OR_COMMAND_MODE_PLACEHOLDER"
          :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
          borderless
          @input="getAutocompleteOptions"
          @keydown="onKeydown"
        />
        <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">
          {{ $options.i18n.SEARCH_DESCRIBED_BY_WITH_RESULTS }}
        </span>

        <fake-search-input
          v-if="isCommandMode"
          :user-input="commandPaletteQuery"
          :scope="commandChar"
          class="fake-input-wrapper"
        />
      </div>
      <span
        role="region"
        :data-testid="$options.SEARCH_RESULTS_DESCRIPTION"
        class="gl-sr-only"
        aria-live="polite"
        aria-atomic="true"
      >
        {{ searchResultsDescription }}
      </span>
      <div
        ref="resultsList"
        class="global-search-results gl-flex gl-w-full gl-grow gl-flex-col gl-overflow-hidden"
        @keydown="onKeydown"
      >
        <scroll-scrim class="gl-grow !gl-overflow-x-hidden" data-testid="nav-container">
          <div class="gl-pb-3">
            <command-palette-items
              v-if="isCommandMode"
              :search-query="commandPaletteQuery"
              :handle="commandChar"
              @updated="highlightFirstCommand"
            />
            <template v-else>
              <global-search-scoped-items v-if="showScopedSearchItems" />
              <global-search-default-items v-if="showDefaultItems" />
              <global-search-autocomplete-items v-else />
            </template>
          </div>
        </scroll-scrim>
      </div>
      <template v-if="searchContext">
        <input
          v-if="searchContext.group"
          type="hidden"
          name="group_id"
          :value="searchContext.group.id"
        />
        <input
          v-if="searchContext.project"
          type="hidden"
          name="project_id"
          :value="searchContext.project.id"
        />

        <template v-if="searchContext.group || searchContext.project">
          <input type="hidden" name="scope" :value="searchContext.scope" />
          <input type="hidden" name="search_code" :value="searchContext.code_search" />
        </template>

        <input type="hidden" name="snippets" :value="searchContext.for_snippets" />
        <input type="hidden" name="repository_ref" :value="searchContext.ref" />
      </template>
    </form>
    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-grow gl-items-center gl-justify-between">
        <span class="gl-text-subtle"
          >{{ $options.i18n.COMMAND_PALETTE_TIP }} <command-palette-lottery
        /></span>
        <span
          ><commands-overview-dropdown
            ref="commandDropdown"
            :items="commandPaletteDropdownItems"
            @selected="handleCommandSelection"
            @hidden="handleClosing"
        /></span>
      </div>
    </template>
  </gl-modal>
</template>

<style scoped>
.input-box-wrapper {
  position: relative;
}
.fake-input-wrapper {
  position: absolute;
}
</style>
