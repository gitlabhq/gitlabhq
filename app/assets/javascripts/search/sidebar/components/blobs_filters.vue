<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { SEARCH_TYPE_ADVANCED } from '../constants';
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
  computed: {
    ...mapState(['searchType']),
    ...mapGetters(['showArchived']),
    showLanguageFilter() {
      return this.searchType === SEARCH_TYPE_ADVANCED;
    },
  },
};
</script>

<template>
  <filters-template>
    <language-filter v-if="showLanguageFilter" class="gl-mb-5" />
    <archived-filter v-if="showArchived" class="gl-mb-5" />
  </filters-template>
</template>
