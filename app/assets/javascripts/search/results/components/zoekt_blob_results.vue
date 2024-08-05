<script>
import { GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import {
  DEFAULT_FETCH_CHUNKS,
  PROJECT_GRAPHQL_ID_TYPE,
  GROUP_GRAPHQL_ID_TYPE,
  SEARCH_RESULTS_DEBOUNCE,
} from '~/search/results/constants';

export default {
  name: 'ZoektBlobResults',
  components: {
    GlLoadingIcon,
  },
  i18n: {
    headerText: __('Search results'),
    blobDataFetchError: s__(
      'GlobalSearch|Could not load search results. Please refresh the page to try again.',
    ),
  },
  data() {
    return {
      hasError: false,
      blobSearch: [],
    };
  },
  apollo: {
    blobSearch: {
      query() {
        return getBlobSearchQuery;
      },
      variables() {
        return {
          search: this.query.search,
          groupId:
            this.query.group_id && convertToGraphQLId(GROUP_GRAPHQL_ID_TYPE, this.query.group_id),
          projectId:
            this.query.project_id &&
            convertToGraphQLId(PROJECT_GRAPHQL_ID_TYPE, this.query.project_id),
          page: this.query.page,
          chunkCount: DEFAULT_FETCH_CHUNKS,
          regex: this.query.regex ? JSON.parse(this.query.regex) : false,
        };
      },
      result({ data }) {
        this.blobSearch = data?.blobSearch;
        this.hasError = false;
      },
      debounce: SEARCH_RESULTS_DEBOUNCE,
      error(error) {
        this.hasError = true;
        createAlert({
          message: this.$options.i18n.blobDataFetchError,
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    ...mapState(['query']),
    isLoading() {
      return this.$apollo.queries.blobSearch.loading;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-justify-center gl-flex-col">
    <gl-loading-icon v-if="isLoading" size="sm" />
  </div>
</template>
