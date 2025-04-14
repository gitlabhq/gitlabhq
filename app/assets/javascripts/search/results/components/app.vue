<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { __, s__ } from '~/locale';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { DEFAULT_FETCH_CHUNKS } from '../constants';
import { RECEIVE_NAVIGATION_COUNT } from '../../store/mutation_types';
import EmptyResult from './result_empty.vue';
import ErrorResult from './result_error.vue';
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
    EmptyResult,
    ErrorResult,
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
    ...mapState(['query']),
    currentPage() {
      return this.query?.page ? parseInt(this.query?.page, 10) : 1;
    },
    isLoading() {
      return this.$apollo.queries.blobSearch.loading;
    },
  },
};
</script>

<template>
  <div>
    <error-result v-if="hasError" />
    <section v-else>
      <status-bar v-if="!isLoading" :blob-search="blobSearch" />
      <empty-result v-if="!hasResults && !isLoading" />
      <zoekt-blob-results
        v-if="hasResults"
        :blob-search="blobSearch"
        :has-results="hasResults"
        :is-loading="isLoading"
      />
    </section>
  </div>
</template>
