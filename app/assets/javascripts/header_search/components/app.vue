<script>
import { GlSearchBoxByType, GlOutsideDirective as Outside } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
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
  },
  data() {
    return {
      showDropdown: false,
    };
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['searchQuery']),
    searchText: {
      get() {
        return this.search;
      },
      set(value) {
        this.setSearch(value);
      },
    },
    showSearchDropdown() {
      return this.showDropdown && gon?.current_username;
    },
    showDefaultItems() {
      return !this.searchText;
    },
  },
  methods: {
    ...mapActions(['setSearch']),
    openDropdown() {
      this.showDropdown = true;
    },
    closeDropdown() {
      this.showDropdown = false;
    },
    submitSearch() {
      return visitUrl(this.searchQuery);
    },
  },
};
</script>

<template>
  <section v-outside="closeDropdown" class="header-search gl-relative">
    <gl-search-box-by-type
      v-model="searchText"
      :debounce="500"
      autocomplete="off"
      :placeholder="$options.i18n.searchPlaceholder"
      @focus="openDropdown"
      @click="openDropdown"
      @keydown.enter="submitSearch"
      @keydown.esc="closeDropdown"
    />
    <div
      v-if="showSearchDropdown"
      data-testid="header-search-dropdown-menu"
      class="header-search-dropdown-menu gl-overflow-y-auto gl-absolute gl-left-0 gl-z-index-1 gl-w-full gl-bg-white gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-200 gl-shadow-x0-y2-b4-s0"
    >
      <div class="header-search-dropdown-content gl-overflow-y-auto gl-py-2">
        <header-search-default-items v-if="showDefaultItems" />
        <template v-else>
          <header-search-scoped-items />
        </template>
      </div>
    </div>
  </section>
</template>
