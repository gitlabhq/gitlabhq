<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'MilestonesFilters',
  components: {
    ArchivedFilter,
    FiltersTemplate,
  },
  computed: {
    ...mapGetters(['showArchived']),
  },
};
</script>

<template>
  <filters-template>
    <archived-filter v-if="showArchived" class="gl-mb-5" />
  </filters-template>
</template>
