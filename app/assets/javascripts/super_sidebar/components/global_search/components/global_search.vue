<script>
import {
  GlSearchBoxByType,
  GlOutsideDirective as Outside,
  GlIcon,
  GlToken,
  GlTooltipDirective,
  GlResizeObserverDirective,
  GlModal,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce, clamp } from 'lodash';
import { truncate } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import { ARROW_DOWN_KEY, ARROW_UP_KEY, END_KEY, HOME_KEY, ESC_KEY } from '~/lib/utils/keys';
import {
  MIN_SEARCH_TERM,
  SEARCH_GITLAB,
  SEARCH_DESCRIBED_BY_WITH_RESULTS,
  SEARCH_DESCRIBED_BY_DEFAULT,
  SEARCH_DESCRIBED_BY_UPDATED,
  SEARCH_RESULTS_LOADING,
  SEARCH_RESULTS_SCOPE,
} from '~/vue_shared/global_search/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SCOPE_TOKEN_MAX_LENGTH,
  INPUT_FIELD_PADDING,
  SEARCH_MODAL_ID,
  SEARCH_INPUT_SELECTOR,
  SEARCH_RESULTS_ITEM_SELECTOR,
} from '../constants';
import CommandPaletteItems from '../command_palette/command_palette_items.vue';
import FakeSearchInput from '../command_palette/fake_search_input.vue';
import {
  COMMON_HANDLES,
  PATH_HANDLE,
  SEARCH_OR_COMMAND_MODE_PLACEHOLDER,
} from '../command_palette/constants';
import GlobalSearchAutocompleteItems from './global_search_autocomplete_items.vue';
import GlobalSearchDefaultItems from './global_search_default_items.vue';
import GlobalSearchScopedItems from './global_search_scoped_items.vue';

export default {
  name: 'GlobalSearchModal',
  SEARCH_MODAL_ID,
  i18n: {
    SEARCH_GITLAB,
    SEARCH_DESCRIBED_BY_WITH_RESULTS,
    SEARCH_DESCRIBED_BY_DEFAULT,
    SEARCH_DESCRIBED_BY_UPDATED,
    SEARCH_RESULTS_LOADING,
    SEARCH_RESULTS_SCOPE,
    MIN_SEARCH_TERM,
  },
  directives: { Outside, GlTooltip: GlTooltipDirective, GlResizeObserverDirective },
  components: {
    GlSearchBoxByType,
    GlobalSearchDefaultItems,
    GlobalSearchScopedItems,
    GlobalSearchAutocompleteItems,
    GlIcon,
    GlToken,
    GlModal,
    CommandPaletteItems,
    FakeSearchInput,
  },
  mixins: [glFeatureFlagMixin()],
  data() {
    return {
      nextFocusedItemIndex: null,
    };
  },
  computed: {
    ...mapState(['search', 'loading', 'searchContext']),
    ...mapGetters(['searchQuery', 'searchOptions', 'scopedSearchOptions']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    searchPlaceholder() {
      return this.glFeatures?.commandPalette ? SEARCH_OR_COMMAND_MODE_PLACEHOLDER : SEARCH_GITLAB;
    },
    showDefaultItems() {
      return !this.searchText;
    },
    searchTermOverMin() {
      return this.searchText?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;
    },
    showScopedSearchItems() {
      return this.searchTermOverMin && this.scopedSearchOptions.length > 1;
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
    showScopeToken() {
      return this.searchTermOverMin && !this.isCommandMode;
    },
    searchBarItem() {
      return this.searchOptions?.[0];
    },
    scopeTokenText() {
      return this.searchBarItem?.scope || this.searchBarItem?.description;
    },
    scopeTokenIcon() {
      if (!this.isCommandMode) {
        return this.searchBarItem?.icon;
      }
      return null;
    },
    searchScope() {
      return sprintf(this.$options.i18n.SEARCH_RESULTS_SCOPE, {
        scope: this.scopeTokenText,
      });
    },
    truncatedSearchScope() {
      return truncate(this.searchScope, SCOPE_TOKEN_MAX_LENGTH);
    },
    searchTextFirstChar() {
      return this.searchText?.trim().charAt(0);
    },
    isCommandMode() {
      return (
        this.glFeatures?.commandPalette &&
        (COMMON_HANDLES.includes(this.searchTextFirstChar) ||
          (this.searchContext.project && this.searchTextFirstChar === PATH_HANDLE))
      );
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
    ...mapActions(['setSearch', 'fetchAutocompleteOptions', 'clearAutocomplete']),
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
    observeTokenWidth({ contentRect: { width } }) {
      const inputField = this.$refs?.searchInputBox?.$el?.querySelector('input');
      if (!inputField) {
        return;
      }
      inputField.style.paddingRight = `${width + INPUT_FIELD_PADDING}px`;
    },
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
      } else {
        stop = false;
      }

      if (stop) {
        event.preventDefault();
      }
    },
    focusSearchInput() {
      this.$refs.searchInput.$el.querySelector('input').focus();
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
    hide-footer
    hide-header-close
    scrollable
    body-class="gl-p-0!"
    modal-class="global-search-modal"
    :centered="false"
    @shown="onSearchModalShown"
    @hide="onSearchModalHidden"
  >
    <form
      role="search"
      :aria-label="searchPlaceholder"
      class="gl-relative gl-rounded-base gl-w-full gl-pb-0"
    >
      <div class="gl-relative gl-bg-white gl-border-b gl-mb-n1 gl-p-3">
        <gl-search-box-by-type
          id="search"
          ref="searchInput"
          v-model="searchText"
          role="searchbox"
          data-testid="global-search-input"
          autocomplete="off"
          :placeholder="searchPlaceholder"
          :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
          borderless
          @input="getAutocompleteOptions"
          @keydown.enter.stop.prevent="submitSearch"
          @keydown="onKeydown"
        />
        <gl-token
          v-if="showScopeToken"
          v-gl-resize-observer-directive="observeTokenWidth"
          class="search-scope-help gl-absolute gl-sm-display-block gl-display-none"
          view-only
          :title="searchScope"
        >
          <gl-icon
            v-if="scopeTokenIcon"
            class="gl-mr-2"
            :aria-label="scopeTokenText"
            :name="scopeTokenIcon"
            :size="16"
          />
          {{ truncatedSearchScope }}
        </gl-token>
        <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">
          {{ $options.i18n.SEARCH_DESCRIBED_BY_WITH_RESULTS }}
        </span>

        <fake-search-input
          v-if="isCommandMode"
          :user-input="commandPaletteQuery"
          :scope="searchTextFirstChar"
          class="gl-absolute"
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
        class="global-search-results gl-overflow-y-auto gl-w-full gl-pb-3"
        @keydown="onKeydown"
      >
        <command-palette-items
          v-if="isCommandMode"
          :search-query="commandPaletteQuery"
          :handle="searchTextFirstChar"
          @updated="highlightFirstCommand"
        />

        <global-search-default-items v-else-if="showDefaultItems" />

        <template v-else>
          <global-search-scoped-items v-if="showScopedSearchItems" />
          <global-search-autocomplete-items />
        </template>
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
  </gl-modal>
</template>
