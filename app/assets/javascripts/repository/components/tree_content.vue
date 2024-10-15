<script>
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { createAlert } from '~/alert';
import {
  TREE_PAGE_SIZE,
  TREE_PAGE_LIMIT,
  COMMIT_BATCH_SIZE,
  GITALY_UNAVAILABLE_CODE,
  i18n,
} from '../constants';
import getRefMixin from '../mixins/get_ref';
import { getRefType } from '../utils/ref_type';
import projectPathQuery from '../queries/project_path.query.graphql';
import { readmeFile } from '../utils/readme';
import { loadCommits, isRequested, resetRequestedCommits } from '../commits_service';
import FilePreview from './preview/index.vue';
import FileTable from './table/index.vue';

export default {
  i18n,
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
  inject: ['refType'],
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
      commits: [],
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
      resetRequestedCommits();
      this.fetchFiles();
    },
  },
  mounted() {
    // We need to wait for `ref` and `projectPath` to be set
    this.$nextTick(() => {
      resetRequestedCommits();
      this.fetchFiles();
    });
  },
  methods: {
    fetchFiles() {
      const originalPath = this.path || '/';
      this.isLoadingFiles = true;

      return this.$apollo
        .query({
          query: paginatedTreeQuery,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            refType: getRefType(this.refType),
            path: originalPath,
            nextPageCursor: this.nextPageCursor,
            pageSize: TREE_PAGE_SIZE,
          },
        })
        .then(({ data }) => {
          if (data.errors) throw data.errors;
          if (!data?.project?.repository || originalPath !== (this.path || '/')) return;

          const {
            project: {
              repository: {
                paginatedTree: { pageInfo },
              },
            },
          } = data;

          this.isLoadingFiles = false;
          this.entries = Object.keys(this.entries).reduce(
            (acc, key) => ({
              ...acc,
              [key]: this.normalizeData(key, data.project.repository.paginatedTree.nodes[0][key]),
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
          let gitalyUnavailableError;
          if (error.graphQLErrors) {
            gitalyUnavailableError = error.graphQLErrors.find(
              (e) => e?.extensions?.code === GITALY_UNAVAILABLE_CODE,
            );
          }
          const message = gitalyUnavailableError
            ? this.$options.i18n.gitalyError
            : this.$options.i18n.generalError;
          createAlert({
            message,
            captureError: true,
          });
        });
    },
    normalizeData(key, data) {
      return this.entries[key].concat(data.nodes);
    },
    hasNextPage(data) {
      return []
        .concat(data.trees.pageInfo, data.submodules.pageInfo, data.blobs.pageInfo)
        .find(({ hasNextPage }) => hasNextPage);
    },
    handleRowAppear(rowNumber) {
      if (isRequested(rowNumber)) {
        return;
      }

      // Assume we are loading from the top and greedily choose offsets in multiples of COMMIT_BATCH_SIZE to minimize number of requests
      this.loadCommitData(rowNumber - (rowNumber % COMMIT_BATCH_SIZE));
    },
    loadCommitData(rowNumber) {
      loadCommits(this.projectPath, this.path, this.ref, rowNumber, this.refType)
        .then(this.setCommitData)
        .catch(() => {});
    },
    setCommitData(data) {
      this.commits = this.commits.concat(data);
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
      :commits="commits"
      @showMore="handleShowMore"
      @row-appear="handleRowAppear"
    />
    <file-preview v-if="readme" :blob="readme" />
  </div>
</template>
