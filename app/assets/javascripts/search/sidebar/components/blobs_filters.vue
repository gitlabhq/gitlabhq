<script>
import LanguageFilter from './language_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'BlobsFilters',
  components: {
    LanguageFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
};
</script>

<template>
  <filters-template>
    <language-filter class="gl-mb-5" />
    <archived-filter class="gl-mb-5" />
  </filters-template>
</template>
