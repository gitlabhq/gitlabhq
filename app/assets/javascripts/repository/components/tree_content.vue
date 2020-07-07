<script>
import createFlash from '~/flash';
import { __ } from '../../locale';
import FileTable from './table/index.vue';
import getRefMixin from '../mixins/get_ref';
import filesQuery from '../queries/files.query.graphql';
import projectPathQuery from '../queries/project_path.query.graphql';
import vueFileListLfsBadgeQuery from '../queries/vue_file_list_lfs_badge.query.graphql';
import FilePreview from './preview/index.vue';
import { readmeFile } from '../utils/readme';

const PAGE_SIZE = 100;

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
    vueFileListLfsBadge: {
      query: vueFileListLfsBadgeQuery,
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
      vueFileListLfsBadge: false,
    };
  },
  computed: {
    readme() {
      return readmeFile(this.entries.blobs);
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
      this.isLoadingFiles = true;

      return this.$apollo
        .query({
          query: filesQuery,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            path: this.path || '/',
            nextPageCursor: this.nextPageCursor,
            pageSize: PAGE_SIZE,
            vueLfsEnabled: this.vueFileListLfsBadge,
          },
        })
        .then(({ data }) => {
          if (data.errors) throw data.errors;
          if (!data?.project?.repository) return;

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
            this.fetchFiles();
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
    />
    <file-preview v-if="readme" :blob="readme" />
  </div>
</template>
