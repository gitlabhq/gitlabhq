<script>
import { GlSearchBoxByType, GlOutsideDirective as Outside } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import { FIRST_DROPDOWN_INDEX, SEARCH_BOX_INDEX } from '../constants';
import HeaderSearchAutocompleteItems from './header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from './header_search_default_items.vue';
import HeaderSearchScopedItems from './header_search_scoped_items.vue';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchPlaceholder: __('Search or jump to...'),
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
    ...mapState(['search']),
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
  },
  methods: {
    ...mapActions(['setSearch', 'fetchAutocompleteOptions']),
    openDropdown() {
      this.showDropdown = true;
    },
    closeDropdown() {
      this.showDropdown = false;
    },
    submitSearch() {
      return visitUrl(this.currentFocusedOption?.url || this.searchQuery);
    },
    getAutocompleteOptions(searchTerm) {
      if (!searchTerm) {
        return;
      }

      this.fetchAutocompleteOptions();
    },
  },
  SEARCH_BOX_INDEX,
};
</script>

<template>
  <section v-outside="closeDropdown" class="header-search gl-relative">
    <gl-search-box-by-type
      v-model="searchText"
      class="gl-z-index-1"
      :debounce="500"
      autocomplete="off"
      :placeholder="$options.i18n.searchPlaceholder"
      @focus="openDropdown"
      @click="openDropdown"
      @input="getAutocompleteOptions"
      @keydown.enter.stop.prevent="submitSearch"
    />
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
  </section>
</template>
