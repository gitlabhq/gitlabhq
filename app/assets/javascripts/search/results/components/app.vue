<script>
import { GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { __, s__ } from '~/locale';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import { SCOPE_BLOB, SEARCH_TYPE_ZOEKT } from '~/search/sidebar/constants/index';
import { parseBoolean } from '~/lib/utils/common_utils';
import { DEFAULT_FETCH_CHUNKS } from '../constants';
import { RECEIVE_NAVIGATION_COUNT } from '../../store/mutation_types';
import StatusBar from './status_bar.vue';

import ZoektBlobResults from './zoekt_blob_results.vue';

export default {
  name: 'GlobalSearchResultsApp',
  i18n: {
    headerText: __('Search results'),
    blobDataFetchError: s__(
      'GlobalSearch|Could not load search results. Refresh the page to try again.',
    ),
  },
  components: {
    ZoektBlobResults,
    StatusBar,
    GlAlert,
  },
  data() {
    return {
      hasError: false,
      blobSearch: {},
      hasResults: true,
    };
  },
  apollo: {
    blobSearch: {
      query() {
        return getBlobSearchQuery;
      },
      errorPolicy: 'none',
      variables() {
        return {
          search: this.query.search,
          groupId: this.query.group_id && `gid://gitlab/Group/${this.query.group_id}`,
          projectId: this.query.project_id && `gid://gitlab/Project/${this.query.project_id}`,
          page: this.currentPage,
          chunkCount: DEFAULT_FETCH_CHUNKS,
          regex: parseBoolean(this.query.regex),
          includeArchived: parseBoolean(this.query.include_archived),
          includeForked: parseBoolean(this.query.include_forked),
        };
      },
      result({ data }) {
        this.hasError = false;
        this.blobSearch = data?.blobSearch;
        this.hasResults = data?.blobSearch?.files?.length > 0;
        this.$store.commit(RECEIVE_NAVIGATION_COUNT, {
          key: 'blobs',
          count: data?.blobSearch?.matchCount.toString(),
        });
      },
      debounce: 500,
      error() {
        this.hasError = true;
        this.hasResults = false;
      },
    },
  },
  computed: {
    ...mapState(['searchType', 'query']),
    ...mapGetters(['currentScope']),
    currentPage() {
      return this.query?.page ? parseInt(this.query?.page, 10) : 1;
    },
    isBlobScope() {
      return this.currentScope === SCOPE_BLOB;
    },
    isZoektSearch() {
      return this.searchType === SEARCH_TYPE_ZOEKT;
    },
    isLoading() {
      return this.$apollo.queries.blobSearch.loading;
    },
  },
  methods: {
    clearErrors() {
      this.hasError = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="hasError" variant="danger" @dismiss="clearErrors">
      {{ $options.i18n.blobDataFetchError }}
    </gl-alert>
    <section v-else-if="isBlobScope && isZoektSearch">
      <status-bar :blob-search="blobSearch" :has-results="hasResults" :is-loading="isLoading" />
      <zoekt-blob-results
        :blob-search="blobSearch"
        :has-results="hasResults"
        :is-loading="isLoading"
      />
    </section>
  </div>
</template>
