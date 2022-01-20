<script>
import { GlSearchBoxByType, GlOutsideDirective as Outside } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { debounce } from 'lodash';
import { visitUrl } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, sprintf } from '~/locale';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import {
  FIRST_DROPDOWN_INDEX,
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
} from '../constants';
import HeaderSearchAutocompleteItems from './header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from './header_search_default_items.vue';
import HeaderSearchScopedItems from './header_search_scoped_items.vue';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchGitlab: s__('GlobalSearch|Search GitLab'),
    searchInputDescribeByNoDropdown: s__(
      'GlobalSearch|Type and press the enter key to submit search.',
    ),
    searchInputDescribeByWithDropdown: s__(
      'GlobalSearch|Type for new suggestions to appear below.',
    ),
    searchDescribedByDefault: s__(
      'GlobalSearch|%{count} default results provided. Use the up and down arrow keys to navigate search results list.',
    ),
    searchDescribedByUpdated: s__(
      'GlobalSearch|Results updated. %{count} results available. Use the up and down arrow keys to navigate search results list, or ENTER to submit.',
    ),
    searchResultsLoading: s__('GlobalSearch|Search results are loading'),
  },
  directives: { Outside },
  components: {
    GlSearchBoxByType,
    HeaderSearchDefaultItems,
    HeaderSearchScopedItems,
    HeaderSearchAutocompleteItems,
    DropdownKeyboardNavigation,
  },
  data() {
    return {
      showDropdown: false,
      currentFocusIndex: SEARCH_BOX_INDEX,
    };
  },
  computed: {
    ...mapState(['search', 'loading']),
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
      return gon?.current_username;
    },
    showSearchDropdown() {
      return this.showDropdown && this.isLoggedIn;
    },
    showDefaultItems() {
      return !this.searchText;
    },
    defaultIndex() {
      if (this.showDefaultItems) {
        return SEARCH_BOX_INDEX;
      }

      return FIRST_DROPDOWN_INDEX;
    },
    searchInputDescribeBy() {
      if (this.isLoggedIn) {
        return this.$options.i18n.searchInputDescribeByWithDropdown;
      }

      return this.$options.i18n.searchInputDescribeByNoDropdown;
    },
    dropdownResultsDescription() {
      if (!this.showSearchDropdown) {
        return ''; // This allows aria-live to see register an update when the dropdown is shown
      }

      if (this.showDefaultItems) {
        return sprintf(this.$options.i18n.searchDescribedByDefault, {
          count: this.searchOptions.length,
        });
      }

      return this.loading
        ? this.$options.i18n.searchResultsLoading
        : sprintf(this.$options.i18n.searchDescribedByUpdated, {
            count: this.searchOptions.length,
          });
    },
  },
  methods: {
    ...mapActions(['setSearch', 'fetchAutocompleteOptions', 'clearAutocomplete']),
    openDropdown() {
      this.showDropdown = true;
    },
    closeDropdown() {
      this.showDropdown = false;
    },
    submitSearch() {
      return visitUrl(this.currentFocusedOption?.url || this.searchQuery);
    },
    getAutocompleteOptions: debounce(function debouncedSearch(searchTerm) {
      if (!searchTerm) {
        this.clearAutocomplete();
      } else {
        this.fetchAutocompleteOptions();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  },
  SEARCH_BOX_INDEX,
  SEARCH_INPUT_DESCRIPTION,
  SEARCH_RESULTS_DESCRIPTION,
};
</script>

<template>
  <form
    v-outside="closeDropdown"
    role="search"
    :aria-label="$options.i18n.searchGitlab"
    class="header-search gl-relative"
  >
    <gl-search-box-by-type
      id="search"
      v-model="searchText"
      role="searchbox"
      class="gl-z-index-1"
      autocomplete="off"
      :placeholder="$options.i18n.searchGitlab"
      :aria-activedescendant="currentFocusedId"
      :aria-describedby="$options.SEARCH_INPUT_DESCRIPTION"
      @focus="openDropdown"
      @click="openDropdown"
      @input="getAutocompleteOptions"
      @keydown.enter.stop.prevent="submitSearch"
    />
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
      class="header-search-dropdown-menu gl-absolute gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0"
    >
      <div class="header-search-dropdown-content gl-overflow-y-auto gl-py-2">
        <dropdown-keyboard-navigation
          v-model="currentFocusIndex"
          :max="searchOptions.length - 1"
          :min="$options.SEARCH_BOX_INDEX"
          :default-index="defaultIndex"
          @tab="closeDropdown"
        />
        <header-search-default-items
          v-if="showDefaultItems"
          :current-focused-option="currentFocusedOption"
        />
        <template v-else>
          <header-search-scoped-items :current-focused-option="currentFocusedOption" />
          <header-search-autocomplete-items :current-focused-option="currentFocusedOption" />
        </template>
      </div>
    </div>
  </form>
</template>
