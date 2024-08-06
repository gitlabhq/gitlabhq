<script>
import { GlLoadingIcon, GlCard, GlPagination } from '@gitlab/ui';
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
  DEFAULT_SHOW_CHUNKS,
} from '~/search/results/constants';
import BlobHeader from '~/search/results/components/blob_header.vue';
import BlobFooter from '~/search/results/components/blob_footer.vue';
import BlobBody from '~/search/results/components/blob_body.vue';
import EmptyResult from '~/search/results/components/result_empty.vue';

export default {
  name: 'ZoektBlobResults',
  components: {
    GlLoadingIcon,
    GlCard,
    BlobHeader,
    BlobFooter,
    BlobBody,
    GlPagination,
    EmptyResult,
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
    hasResults() {
      return this.blobSearch?.files?.length > 0;
    },
  },
  methods: {
    hasMore(file) {
      const showingMatches = file.chunks
        .slice(0, DEFAULT_SHOW_CHUNKS)
        .reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);
      const matchesTotal = file.chunks.reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);

      return file.matchCount !== 0 && matchesTotal > showingMatches;
    },
    hasCode(file) {
      return file?.chunks.length > 0;
    },
    projectPathAndFilePath({ projectPath = '', path = '' }) {
      return `${projectPath}:${path}`;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-justify-center gl-flex-col">
    <gl-loading-icon v-if="isLoading" size="sm" />
    <div v-if="hasResults && !isLoading && !hasError" class="gl-relative">
      <gl-card
        v-for="file in blobSearch.files"
        :key="projectPathAndFilePath(file)"
        class="file-result-holder gl-my-5 file-holder"
        :header-class="{
          'gl-border-b-0!': !hasCode(file),
          'gl-new-card-header file-title': true,
        }"
        footer-class="gl-new-card-footer"
        body-class="gl-p-0"
      >
        <template #header>
          <blob-header
            :file-path="file.path"
            :project-path="file.projectPath"
            :file-url="file.fileUrl"
          />
        </template>

        <blob-body v-if="hasCode(file)" :file="file" />

        <template v-if="hasMore(file)" #footer>
          <blob-footer :file="file" />
        </template>
      </gl-card>
    </div>
    <empty-result v-else-if="!hasResults && !isLoading" />
    <template v-if="hasResults && !isLoading && !hasError">
      <gl-pagination
        v-model="query.page"
        class="gl-mx-auto"
        :per-page="blobSearch.perPage"
        :total-items="blobSearch.fileCount"
      />
    </template>
  </div>
</template>
