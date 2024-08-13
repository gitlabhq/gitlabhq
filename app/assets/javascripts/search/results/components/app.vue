<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import { SCOPE_BLOB, SEARCH_TYPE_ZOEKT } from '~/search/sidebar/constants/index';
import ZoektBlobResults from '~/search/results/components/zoekt_blob_results.vue';

export default {
  name: 'GlobalSearchResultsApp',
  i18n: {
    headerText: __('Search results'),
  },
  components: {
    ZoektBlobResults,
  },
  computed: {
    ...mapState(['searchType']),
    ...mapGetters(['currentScope']),
    isBlobScope() {
      return this.currentScope === SCOPE_BLOB;
    },
    isZoektSearch() {
      return this.searchType === SEARCH_TYPE_ZOEKT;
    },
  },
};
</script>

<template>
  <section>
    <zoekt-blob-results v-if="isBlobScope && isZoektSearch" />
  </section>
</template>
