<script>
import LanguageFilter from './language_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'BlobsFilters',
  components: {
    LanguageFilter,
    FiltersTemplate,
  },
};
</script>

<template>
  <filters-template>
    <language-filter class="gl-mb-5" />
  </filters-template>
</template>
