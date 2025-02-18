<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import MembersFilteredSearchBar from './members_filtered_search_bar.vue';
import SortDropdown from './sort_dropdown.vue';

export default {
  name: 'FilterSortContainer',
  components: { MembersFilteredSearchBar, SortDropdown },
  inject: ['namespace'],
  computed: {
    ...mapState({
      filteredSearchBar(state) {
        return state[this.namespace].filteredSearchBar;
      },
      tableSortableFields(state) {
        return state[this.namespace].tableSortableFields;
      },
    }),
    showContainer() {
      return this.filteredSearchBar.show || this.showSortDropdown;
    },
    showSortDropdown() {
      return this.tableSortableFields.length;
    },
  },
};
</script>

<template>
  <div v-if="showContainer" class="gl-bg-subtle gl-p-3 md:gl-flex">
    <members-filtered-search-bar v-if="filteredSearchBar.show" class="gl-grow gl-p-3" />
    <sort-dropdown v-if="showSortDropdown" class="gl-shrink-0 gl-p-3" />
  </div>
</template>
