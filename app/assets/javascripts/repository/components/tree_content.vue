<script>
import filesQuery from 'shared_queries/repository/files.query.graphql';
import createFlash from '~/flash';
import { __ } from '../../locale';
import { TREE_PAGE_SIZE, TREE_INITIAL_FETCH_COUNT, TREE_PAGE_LIMIT } from '../constants';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import { readmeFile } from '../utils/readme';
import FilePreview from './preview/index.vue';
import FileTable from './table/index.vue';

export default {
  components: {
    FileTable,
    FilePreview,
  },
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
  },
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
    loadingPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      projectPath: '',
      nextPageCursor: '',
      pagesLoaded: 1,
      entries: {
        trees: [],
        submodules: [],
        blobs: [],
      },
      isLoadingFiles: false,
      isOverLimit: false,
      clickedShowMore: false,
      fetchCounter: 0,
    };
  },
  computed: {
    pageSize() {
      // we want to exponentially increase the page size to reduce the load on the frontend
      const exponentialSize = (TREE_PAGE_SIZE / TREE_INITIAL_FETCH_COUNT) * (this.fetchCounter + 1);
      return exponentialSize < TREE_PAGE_SIZE ? exponentialSize : TREE_PAGE_SIZE;
    },
    totalEntries() {
      return Object.values(this.entries).flat().length;
    },
    readme() {
      return readmeFile(this.entries.blobs);
    },
    pageLimitReached() {
      return this.totalEntries / this.pagesLoaded >= TREE_PAGE_LIMIT;
    },
    hasShowMore() {
      return !this.clickedShowMore && this.pageLimitReached;
    },
  },

  watch: {
    $route: function routeChange() {
      this.entries.trees = [];
      this.entries.submodules = [];
      this.entries.blobs = [];
      this.nextPageCursor = '';
      this.fetchFiles();
    },
  },
  mounted() {
    // We need to wait for `ref` and `projectPath` to be set
    this.$nextTick(() => this.fetchFiles());
  },
  methods: {
    fetchFiles() {
      const originalPath = this.path || '/';
      this.isLoadingFiles = true;

      return this.$apollo
        .query({
          query: filesQuery,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            path: originalPath,
            nextPageCursor: this.nextPageCursor,
            pageSize: this.pageSize,
          },
        })
        .then(({ data }) => {
          if (data.errors) throw data.errors;
          if (!data?.project?.repository || originalPath !== (this.path || '/')) return;

          const pageInfo = this.hasNextPage(data.project.repository.tree);

          this.isLoadingFiles = false;
          this.entries = Object.keys(this.entries).reduce(
            (acc, key) => ({
              ...acc,
              [key]: this.normalizeData(key, data.project.repository.tree[key].edges),
            }),
            {},
          );

          if (pageInfo?.hasNextPage) {
            this.nextPageCursor = pageInfo.endCursor;
            this.fetchCounter += 1;
            if (!this.pageLimitReached || this.clickedShowMore) {
              this.fetchFiles();
              this.clickedShowMore = false;
            }
          }
        })
        .catch((error) => {
          createFlash({
            message: __('An error occurred while fetching folder content.'),
          });
          throw error;
        });
    },
    normalizeData(key, data) {
      return this.entries[key].concat(data.map(({ node }) => node));
    },
    hasNextPage(data) {
      return []
        .concat(data.trees.pageInfo, data.submodules.pageInfo, data.blobs.pageInfo)
        .find(({ hasNextPage }) => hasNextPage);
    },
    handleShowMore() {
      this.clickedShowMore = true;
      this.pagesLoaded += 1;
      this.fetchFiles();
    },
  },
};
</script>

<template>
  <div>
    <file-table
      :path="path"
      :entries="entries"
      :is-loading="isLoadingFiles"
      :loading-path="loadingPath"
      :has-more="hasShowMore"
      @showMore="handleShowMore"
    />
    <file-preview v-if="readme" :blob="readme" />
  </div>
</template>
