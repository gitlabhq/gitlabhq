<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import StatusFilter from './status_filter/index.vue';
import FiltersTemplate from './filters_template.vue';
import ArchivedFilter from './archived_filter/index.vue';

export default {
  name: 'MergeRequestsFilters',
  components: {
    StatusFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  computed: {
    ...mapGetters(['showArchived']),
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
    <archived-filter v-if="showArchived" class="gl-mb-5" />
  </filters-template>
</template>
