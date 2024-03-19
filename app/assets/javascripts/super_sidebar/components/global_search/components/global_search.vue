<script>
import { GlSearchBoxByType, GlOutsideDirective as Outside, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce, clamp } from 'lodash';
import { visitUrl } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import {
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  END_KEY,
  HOME_KEY,
  ESC_KEY,
  NUMPAD_ENTER_KEY,
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
import { darkModeEnabled } from '~/lib/utils/color_utils';
import ScrollScrim from '~/super_sidebar/components/scroll_scrim.vue';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SEARCH_MODAL_ID,
  SEARCH_INPUT_SELECTOR,
  SEARCH_RESULTS_ITEM_SELECTOR,
} from '../constants';
import CommandPaletteItems from '../command_palette/command_palette_items.vue';
import FakeSearchInput from '../command_palette/fake_search_input.vue';
import { COMMON_HANDLES, SEARCH_OR_COMMAND_MODE_PLACEHOLDER } from '../command_palette/constants';
import CommandPaletteLottery from '../command_palette/command_palette_lottery.vue';
import CommandsOverviewDropdown from '../command_palette/command_overview_dropdown.vue';
import { commandPaletteDropdownItems } from '../utils';
import GlobalSearchAutocompleteItems from './global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from './global_search_default_items.vue';
import GlobalSearchScopedItems from './global_search_scoped_items.vue';

export default {
  name: 'GlobalSearchModal',
  SEARCH_MODAL_ID,
  i18n: {
    COMMAND_PALETTE,
    SEARCH_DESCRIBED_BY_WITH_RESULTS,
    SEARCH_DESCRIBED_BY_DEFAULT,
    SEARCH_DESCRIBED_BY_UPDATED,
    SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
    SEARCH_RESULTS_LOADING,
    MIN_SEARCH_TERM,
    COMMAND_PALETTE_TIP,
    COMMON_HANDLES,
  },
  directives: { Outside },
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
  data() {
    return {
      nextFocusedItemIndex: null,
      commandPaletteDropdownItems,
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
      return darkModeEnabled() ? 'gl-bg-gray-10!' : 'gl-bg-gray-50!';
    },
  },
  watch: {
    nextFocusedItemIndex() {
      this.highlightFirstCommand();
    },
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
    onKeydown(event) {
      const { code, target } = event;

      let stop = true;

      const elements = this.getFocusableOptions();
      if (elements.length < 1) return;

      const isSearchInput = target.matches(SEARCH_INPUT_SELECTOR);

      if (code === HOME_KEY) {
        if (isSearchInput) return;

        this.focusItem(0, elements);
      } else if (code === END_KEY) {
        if (isSearchInput) return;

        this.focusItem(elements.length - 1, elements);
      } else if (code === ARROW_UP_KEY) {
        if (isSearchInput) return;

        if (elements.indexOf(target) === 0) {
          this.focusSearchInput();
        } else {
          this.focusNextItem(event, elements, -1);
        }
      } else if (code === ARROW_DOWN_KEY) {
        this.focusNextItem(event, elements, 1);
      } else if (code === ESC_KEY) {
        this.$refs.searchModal.close();
      } else if (code === NUMPAD_ENTER_KEY) {
        event.target?.firstChild.click();
      } else {
        stop = false;
      }

      if (stop) {
        event.preventDefault();
      }
    },
    focusSearchInput() {
      this.$refs.searchInput.$el.querySelector('input')?.focus();
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
      visitUrl(this.searchQuery);
    },
    runFirstCommand() {
      this.getFocusableOptions()[0]?.firstChild.click();
    },
    onSearchModalShown() {
      this.$emit('shown');
    },
    onSearchModalHidden() {
      this.searchText = '';
      this.$emit('hidden');
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
};
</script>

<template>
  <gl-modal
    ref="searchModal"
    :modal-id="$options.SEARCH_MODAL_ID"
    hide-header
    hide-header-close
    scrollable
    :title="$options.i18n.COMMAND_PALETTE"
    body-class="gl-p-0!"
    modal-class="global-search-modal"
    :centered="false"
    @shown="onSearchModalShown"
    @hide="onSearchModalHidden"
  >
    <form
      role="search"
      :aria-label="$options.i18n.SEARCH_OR_COMMAND_MODE_PLACEHOLDER"
      class="gl-relative gl-rounded-lg gl-w-full gl-pb-0"
    >
      <div class="input-box-wrapper gl-bg-white gl-border-b gl-mb-n1 gl-p-2">
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
          @keydown.enter.stop.prevent="submitSearch"
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
        class="global-search-results gl-w-full gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden"
        @keydown="onKeydown"
      >
        <scroll-scrim class="gl-flex-grow-1 gl-overflow-x-hidden!" data-testid="nav-container">
          <div class="gl-pb-3">
            <command-palette-items
              v-if="isCommandMode"
              :search-query="commandPaletteQuery"
              :handle="commandChar"
              @updated="highlightFirstCommand"
            />

            <global-search-default-items v-else-if="showDefaultItems" />

            <template v-else>
              <global-search-autocomplete-items />
              <global-search-scoped-items v-if="showScopedSearchItems" />
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
      <div
        class="gl-display-flex gl-flex-grow-1 gl-m-0 gl-vertical-align-middle gl-justify-content-space-between"
      >
        <span class="gl-text-gray-500"
          >{{ $options.i18n.COMMAND_PALETTE_TIP }} <command-palette-lottery
        /></span>
        <span
          ><commands-overview-dropdown
            :items="commandPaletteDropdownItems"
            @selected="handleCommandSelection"
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
