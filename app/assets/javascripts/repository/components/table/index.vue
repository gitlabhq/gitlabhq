<script>
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { sprintf, __ } from '../../../locale';
import getRefMixin from '../../mixins/get_ref';
import getFiles from '../../queries/getFiles.graphql';
import getProjectPath from '../../queries/getProjectPath.graphql';
import TableHeader from './header.vue';
import TableRow from './row.vue';
import ParentRow from './parent_row.vue';

const PAGE_SIZE = 100;

export default {
  components: {
    GlLoadingIcon,
    TableHeader,
    TableRow,
    ParentRow,
  },
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: getProjectPath,
    },
  },
  props: {
    path: {
      type: String,
      required: true,
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
    };
  },
  computed: {
    tableCaption() {
      return sprintf(
        __('Files, directories, and submodules in the path %{path} for commit reference %{ref}'),
        { path: this.path, ref: this.ref },
      );
    },
    showParentRow() {
      return !this.isLoadingFiles && ['', '/'].indexOf(this.path) === -1;
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
          query: getFiles,
          variables: {
            projectPath: this.projectPath,
            ref: this.ref,
            path: this.path,
            nextPageCursor: this.nextPageCursor,
            pageSize: PAGE_SIZE,
          },
        })
        .then(({ data }) => {
          if (!data) return;

          const pageInfo = this.hasNextPage(data.project.repository.tree);

          this.isLoadingFiles = false;
          this.entries = Object.keys(this.entries).reduce(
            (acc, key) => ({
              ...acc,
              [key]: this.normalizeData(key, data.project.repository.tree[key].edges),
            }),
            {},
          );

          if (pageInfo && pageInfo.hasNextPage) {
            this.nextPageCursor = pageInfo.endCursor;
            this.fetchFiles();
          }
        })
        .catch(() => createFlash(__('An error occurred while fetching folder content.')));
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
  <div class="tree-content-holder">
    <div class="table-holder bordered-box">
      <table class="table tree-table qa-file-tree" aria-live="polite">
        <caption class="sr-only">
          {{
            tableCaption
          }}
        </caption>
        <table-header v-once />
        <tbody>
          <parent-row v-show="showParentRow" :commit-ref="ref" :path="path" />
          <template v-for="val in entries">
            <table-row
              v-for="entry in val"
              :id="entry.id"
              :key="`${entry.flatPath}-${entry.id}`"
              :current-path="path"
              :path="entry.flatPath"
              :type="entry.type"
              :url="entry.webUrl"
            />
          </template>
        </tbody>
      </table>
      <gl-loading-icon v-show="isLoadingFiles" class="my-3" size="md" />
    </div>
  </div>
</template>
