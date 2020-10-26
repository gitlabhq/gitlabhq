<script>
import filesQuery from 'shared_queries/repository/files.query.graphql';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __ } from '../../locale';
import FileTable from './table/index.vue';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import FilePreview from './preview/index.vue';
import { readmeFile } from '../utils/readme';

const LIMIT = 1000;
const PAGE_SIZE = 100;
export const INITIAL_FETCH_COUNT = LIMIT / PAGE_SIZE;

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
      entries: {
        trees: [],
        submodules: [],
        blobs: [],
      },
      isLoadingFiles: false,
      isOverLimit: false,
      clickedShowMore: false,
      pageSize: PAGE_SIZE,
      fetchCounter: 0,
    };
  },
  computed: {
    readme() {
      return readmeFile(this.entries.blobs);
    },
    hasShowMore() {
      return !this.clickedShowMore && this.fetchCounter === INITIAL_FETCH_COUNT;
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
            if (this.fetchCounter < INITIAL_FETCH_COUNT || this.clickedShowMore) {
              this.fetchFiles();
              this.clickedShowMore = false;
            }
          }
        })
        .catch(error => {
          createFlash(__('An error occurred while fetching folder content.'));
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
