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
import {
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SCOPE_TOKEN_MAX_LENGTH,
  INPUT_FIELD_PADDING,
  IS_SEARCHING,
  SEARCH_MODAL_ID,
  SEARCH_INPUT_SELECTOR,
  SEARCH_RESULTS_ITEM_SELECTOR,
} from '../constants';
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
    searchBarClasses() {
      return {
        [IS_SEARCHING]: this.searchTermOverMin,
      };
    },
    showScopeHelp() {
      return this.searchTermOverMin;
    },
    searchBarItem() {
      return this.searchOptions?.[0];
    },
    infieldHelpContent() {
      return this.searchBarItem?.scope || this.searchBarItem?.description;
    },
    infieldHelpIcon() {
      return this.searchBarItem?.icon;
    },
    scopeTokenTitle() {
      return sprintf(this.$options.i18n.SEARCH_RESULTS_SCOPE, {
        scope: this.infieldHelpContent,
      });
    },
  },
  methods: {
    ...mapActions(['setSearch', 'fetchAutocompleteOptions', 'clearAutocomplete']),
    getAutocompleteOptions: debounce(function debouncedSearch(searchTerm) {
      if (!searchTerm) {
        this.clearAutocomplete();
      } else {
        this.fetchAutocompleteOptions();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    getTruncatedScope(scope) {
      return truncate(scope, SCOPE_TOKEN_MAX_LENGTH);
    },
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
        this.focusItem(0, elements);
      } else if (code === END_KEY) {
        this.focusItem(elements.length - 1, elements);
      } else if (code === ARROW_UP_KEY) {
        if (isSearchInput) return;

        if (elements.indexOf(target) === 0) {
          this.focusSearchInput();
          return;
        }
        this.focusNextItem(event, elements, -1);
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
      this.$refs.searchInputBox.$el.querySelector('input').focus();
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
      if (this.search?.length <= SEARCH_SHORTCUTS_MIN_CHARACTERS) {
        return;
      }
      visitUrl(this.searchQuery);
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
    @hidden="$emit('hidden')"
    @shown="$emit('shown')"
  >
    <form
      role="search"
      :aria-label="$options.i18n.SEARCH_GITLAB"
      class="gl-relative gl-rounded-base gl-w-full"
      :class="searchBarClasses"
      data-testid="global-search-form"
    >
      <div class="gl-p-1">
        <gl-search-box-by-type
          id="search"
          ref="searchInputBox"
          v-model="searchText"
          role="searchbox"
          data-testid="global-search-input"
          autocomplete="off"
          :placeholder="$options.i18n.SEARCH_GITLAB"
          :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
          borderless
          @input="getAutocompleteOptions"
          @keydown.enter.stop.prevent="submitSearch"
          @keydown="onKeydown"
        />
        <gl-token
          v-if="showScopeHelp"
          v-gl-resize-observer-directive="observeTokenWidth"
          class="in-search-scope-help gl-sm-display-block gl-display-none"
          view-only
          :title="scopeTokenTitle"
        >
          <gl-icon
            v-if="infieldHelpIcon"
            class="gl-mr-2"
            :aria-label="infieldHelpContent"
            :name="infieldHelpIcon"
            :size="16"
          />
          {{
            getTruncatedScope(
              sprintf($options.i18n.SEARCH_RESULTS_SCOPE, { scope: infieldHelpContent }),
            )
          }}
        </gl-token>
        <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">
          {{ $options.i18n.SEARCH_DESCRIBED_BY_WITH_RESULTS }}
        </span>
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
        data-testid="global-search-results"
        class="global-search-results gl-overflow-y-auto gl-w-full gl-pb-2"
        @keydown="onKeydown"
      >
        <global-search-default-items v-if="showDefaultItems" />
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
