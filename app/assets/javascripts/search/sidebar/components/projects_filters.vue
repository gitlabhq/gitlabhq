<script>
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'ProjectsFilters',
  components: {
    ArchivedFilter,
    FiltersTemplate,
  },
};
</script>

<template>
  <filters-template>
    <archived-filter class="gl-mb-5" />
  </filters-template>
</template>
