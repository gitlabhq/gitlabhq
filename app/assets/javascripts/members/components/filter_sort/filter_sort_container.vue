<script>
import { mapState } from 'vuex';
import MembersFilteredSearchBar from './members_filtered_search_bar.vue';

export default {
  name: 'FilterSortContainer',
  components: { MembersFilteredSearchBar },
  computed: {
    ...mapState(['filteredSearchBar']),
  },
};
</script>

<template>
  <div v-if="filteredSearchBar.show" class="gl-bg-gray-10 gl-p-5">
    <members-filtered-search-bar />
  </div>
</template>
