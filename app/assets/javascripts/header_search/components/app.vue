<script>
import {
  GlSearchBoxByType,
  GlIcon,
  GlToken,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce } from 'lodash';
import { visitUrl } from '~/lib/utils/url_utility';
import { truncate } from '~/lib/utils/text_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import Tracking from '~/tracking';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import {
  SEARCH_GITLAB,
  SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN,
  SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN,
  SEARCH_DESCRIBED_BY_DEFAULT,
  SEARCH_DESCRIBED_BY_UPDATED,
  SEARCH_RESULTS_LOADING,
  SEARCH_RESULTS_SCOPE,
  KBD_HELP,
} from '~/vue_shared/global_search/constants';
import {
  FIRST_DROPDOWN_INDEX,
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
  SCOPE_TOKEN_MAX_LENGTH,
  INPUT_FIELD_PADDING,
  IS_SEARCHING,
  IS_FOCUSED,
  IS_NOT_FOCUSED,
  DROPDOWN_CLOSE_TIMEOUT,
} from '../constants';
import HeaderSearchAutocompleteItems from './header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from './header_search_default_items.vue';
import HeaderSearchScopedItems from './header_search_scoped_items.vue';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    SEARCH_GITLAB,
    SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN,
    SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN,
    SEARCH_DESCRIBED_BY_DEFAULT,
    SEARCH_DESCRIBED_BY_UPDATED,
    SEARCH_RESULTS_LOADING,
    SEARCH_RESULTS_SCOPE,
    KBD_HELP,
  },
  directives: { GlTooltip: GlTooltipDirective, GlResizeObserverDirective },
  components: {
    GlSearchBoxByType,
    HeaderSearchDefaultItems,
    HeaderSearchScopedItems,
    HeaderSearchAutocompleteItems,
    DropdownKeyboardNavigation,
    GlIcon,
    GlToken,
  },
  data() {
    return {
      isFocused: false,
      currentFocusIndex: SEARCH_BOX_INDEX,
    };
  },
  computed: {
    ...mapState(['search', 'loading', 'searchContext']),
    ...mapGetters(['searchQuery', 'searchOptions']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    currentFocusedOption() {
      return this.searchOptions[this.currentFocusIndex];
    },
    currentFocusedId() {
      return this.currentFocusedOption?.html_id;
    },
    isLoggedIn() {
      return Boolean(gon?.current_username);
    },
    showSearchDropdown() {
      if (!this.isFocused || !this.isLoggedIn) {
        return false;
      }
      return this.searchOptions?.length > 0;
    },
    showDefaultItems() {
      return !this.searchText;
    },
    searchTermOverMin() {
      return this.searchText?.length > SEARCH_SHORTCUTS_MIN_CHARACTERS;
    },
    defaultIndex() {
      if (this.showDefaultItems) {
        return SEARCH_BOX_INDEX;
      }
      return FIRST_DROPDOWN_INDEX;
    },
    searchInputDescribeBy() {
      if (this.isLoggedIn) {
        return this.$options.i18n.SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN;
      }
      return this.$options.i18n.SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN;
    },
    dropdownResultsDescription() {
      if (!this.showSearchDropdown) {
        return ''; // This allows aria-live to see register an update when the dropdown is shown
      }

      if (this.showDefaultItems) {
        return sprintf(this.$options.i18n.SEARCH_DESCRIBED_BY_DEFAULT, {
          count: this.searchOptions.length,
        });
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
        [IS_FOCUSED]: this.isFocused,
        [IS_NOT_FOCUSED]: !this.isFocused,
      };
    },
    showScopeHelp() {
      return this.searchTermOverMin && this.isFocused;
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
    openDropdown() {
      this.isFocused = true;
      this.$emit('expandSearchBar');

      Tracking.event(undefined, 'focus_input', {
        label: 'global_search',
        property: 'navigation_top',
      });
    },
    collapseAndCloseSearchBar() {
      // without timeout dropdown closes
      // before click event is dispatched
      setTimeout(() => {
        this.isFocused = false;
        this.$emit('collapseSearchBar');

        Tracking.event(undefined, 'blur_input', {
          label: 'global_search',
          property: 'navigation_top',
        });
      }, DROPDOWN_CLOSE_TIMEOUT);
    },
    submitSearch() {
      if (this.search?.length <= SEARCH_SHORTCUTS_MIN_CHARACTERS && this.currentFocusIndex < 0) {
        return null;
      }
      return visitUrl(this.currentFocusedOption?.url || this.searchQuery);
    },
    getAutocompleteOptions: debounce(function debouncedSearch(searchTerm) {
      this.openDropdown();
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
  },
  SEARCH_BOX_INDEX,
  FIRST_DROPDOWN_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
};
</script>

<template>
  <form
    role="search"
    :aria-label="$options.i18n.SEARCH_GITLAB"
    class="header-search gl-relative gl-rounded-base gl-w-full"
    :class="searchBarClasses"
    data-testid="header-search-form"
  >
    <gl-search-box-by-type
      id="search"
      ref="searchInputBox"
      v-model="searchText"
      role="searchbox"
      class="gl-z-index-1"
      data-qa-selector="global_search_input"
      autocomplete="off"
      :placeholder="$options.i18n.SEARCH_GITLAB"
      :aria-activedescendant="currentFocusedId"
      :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
      @focusin="openDropdown"
      @focusout="collapseAndCloseSearchBar"
      @input="getAutocompleteOptions"
      @keydown.enter.stop.prevent="submitSearch"
      @keydown.esc.stop.prevent="collapseAndCloseSearchBar"
    />
    <gl-token
      v-if="showScopeHelp"
      v-gl-resize-observer-directive="observeTokenWidth"
      class="in-search-scope-help"
      :view-only="true"
      :title="scopeTokenTitle"
      ><gl-icon
        v-if="infieldHelpIcon"
        class="gl-mr-2"
        :aria-label="infieldHelpContent"
        :name="infieldHelpIcon"
        :size="16"
      />{{
        getTruncatedScope(
          sprintf($options.i18n.SEARCH_RESULTS_SCOPE, {
            scope: infieldHelpContent,
          }),
        )
      }}
    </gl-token>
    <kbd
      v-show="!isFocused"
      v-gl-tooltip.bottom.hover.html
      class="gl-absolute gl-right-3 gl-top-0 gl-z-index-1 keyboard-shortcut-helper"
      :title="$options.i18n.KBD_HELP"
      >/</kbd
    >
    <span :id="$options.SEARCH_INPUT_DESCRIPTION" role="region" class="gl-sr-only">{{
      searchInputDescribeBy
    }}</span>
    <span
      role="region"
      :data-testid="$options.SEARCH_RESULTS_DESCRIPTION"
      class="gl-sr-only"
      aria-live="polite"
      aria-atomic="true"
    >
      {{ dropdownResultsDescription }}
    </span>
    <div
      v-if="showSearchDropdown"
      data-testid="header-search-dropdown-menu"
      class="header-search-dropdown-menu gl-overflow-y-auto gl-absolute gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0 gl-mt-3"
    >
      <div class="header-search-dropdown-content gl-py-2">
        <dropdown-keyboard-navigation
          v-model="currentFocusIndex"
          :max="searchOptions.length - 1"
          :min="$options.FIRST_DROPDOWN_INDEX"
          :default-index="defaultIndex"
          :enable-cycle="true"
        />
        <header-search-default-items
          v-if="showDefaultItems"
          :current-focused-option="currentFocusedOption"
        />
        <template v-else>
          <header-search-scoped-items
            v-if="searchTermOverMin"
            :current-focused-option="currentFocusedOption"
          />
          <header-search-autocomplete-items :current-focused-option="currentFocusedOption" />
        </template>
      </div>
    </div>
  </form>
</template>
