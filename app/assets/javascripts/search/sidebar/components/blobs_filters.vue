<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { SEARCH_TYPE_ADVANCED, SEARCH_TYPE_ZOEKT } from '../constants';
import LanguageFilter from './language_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import ForksFilter from './forks_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'BlobsFilters',
  components: {
    LanguageFilter,
    FiltersTemplate,
    ArchivedFilter,
    ForksFilter,
  },
  computed: {
    ...mapState(['searchType']),
    ...mapGetters(['hasMissingProjectContext']),
    showLanguageFilter() {
      return this.searchType === SEARCH_TYPE_ADVANCED;
    },
    shouldShowZoektForksFilter() {
      return this.searchType === SEARCH_TYPE_ZOEKT && this.hasMissingProjectContext;
    },
  },
};
</script>

<template>
  <filters-template>
    <language-filter v-if="showLanguageFilter" class="gl-mb-5" />
    <archived-filter v-if="hasMissingProjectContext" class="gl-mb-5" />
    <forks-filter v-if="shouldShowZoektForksFilter" class="gl-mb-5" />
  </filters-template>
</template>
