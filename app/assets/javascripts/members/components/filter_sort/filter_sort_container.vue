<script>
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
  <div v-if="showContainer" class="gl-bg-gray-10 gl-p-3 gl-md-display-flex">
    <members-filtered-search-bar v-if="filteredSearchBar.show" class="gl-p-3 gl-flex-grow-1" />
    <sort-dropdown v-if="showSortDropdown" class="gl-p-3 gl-flex-shrink-0" />
  </div>
</template>
