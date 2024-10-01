<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'CommitsFilters',
  components: {
    ArchivedFilter,
    FiltersTemplate,
  },
  computed: {
    ...mapGetters(['hasMissingProjectContext']),
  },
};
</script>

<template>
  <filters-template>
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
  </filters-template>
</template>
