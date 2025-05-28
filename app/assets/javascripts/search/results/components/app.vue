<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { __, s__ } from '~/locale';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import { ERROR_POLICY_NONE } from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { logError } from '~/lib/logger';
import { EXCLUDE_FORKS_FILTER_PARAM } from '~/search/sidebar/constants';
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
      loaded: false,
    };
  },
  apollo: {
    blobSearch: {
      query() {
        return getBlobSearchQuery;
      },
      errorPolicy: ERROR_POLICY_NONE,
      variables() {
        const variables = {
          search: this.query.search || '',
          page: this.currentPage,
          chunkCount: DEFAULT_FETCH_CHUNKS,
          regex: parseBoolean(this.query?.regex),
          includeArchived: parseBoolean(this.query?.include_archived),
          excludeForks: parseBoolean(this.query?.[EXCLUDE_FORKS_FILTER_PARAM]),
        };

        if (this.query?.group_id) {
          variables.groupId = `gid://gitlab/Group/${this.query.group_id}`;
        }

        if (this.query?.project_id) {
          variables.projectId = `gid://gitlab/Project/${this.query.project_id}`;
        }

        return variables;
      },
      skip() {
        return !this.query.search;
      },
      result({ data }) {
        this.hasError = false;
        this.loaded = true;
        this.blobSearch = data?.blobSearch;
        this.$store.commit(RECEIVE_NAVIGATION_COUNT, {
          key: 'blobs',
          count: data?.blobSearch?.matchCount.toString(),
        });
      },
      debounce: 500,
      error(error) {
        logError(error);
        this.loaded = true;
        this.hasError = true;
      },
    },
  },
  computed: {
    ...mapState(['query']),
    currentPage() {
      return this.query?.page ? parseInt(this.query?.page, 10) : 1;
    },
    isLoading() {
      if (!this.loaded && !this.$apollo?.queries?.blobSearch?.loading) {
        return true;
      }
      return this.$apollo.queries.blobSearch.loading;
    },
    hasResults() {
      return this.blobSearch?.files?.length > 0;
    },
  },
};
</script>

<template>
  <div>
    <error-result v-if="hasError" />
    <section v-else>
      <status-bar v-if="!isLoading" :blob-search="blobSearch" />
      <zoekt-blob-results
        v-if="hasResults || isLoading"
        :blob-search="blobSearch"
        :has-results="hasResults"
        :is-loading="isLoading"
      />
      <empty-result v-else />
    </section>
  </div>
</template>
