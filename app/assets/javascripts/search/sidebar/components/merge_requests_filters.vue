<script>
import StatusFilter from './status_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'MergeRequestsFilters',
  components: {
    StatusFilter,
    FiltersTemplate,
  },
};
</script>

<template>
  <filters-template>
    <status-filter class="gl-mb-5" />
  </filters-template>
</template>
