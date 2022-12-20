<script>
import { GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import getRefMixin from '../../mixins/get_ref';
import projectPathQuery from '../../queries/project_path.query.graphql';
import TableHeader from './header.vue';
import ParentRow from './parent_row.vue';
import TableRow from './row.vue';

export default {
  components: {
    GlSkeletonLoader,
    TableHeader,
    TableRow,
    ParentRow,
    GlButton,
  },
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
  },
  props: {
    commits: {
      type: Array,
      required: false,
      default: () => [],
    },
    path: {
      type: String,
      required: true,
    },
    entries: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    loadingPath: {
      type: String,
      required: false,
      default: '',
    },
    hasMore: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      projectPath: '',
      rowNumbers: {},
    };
  },
  computed: {
    totalEntries() {
      return Object.values(this.entries).flat().length;
    },
    tableCaption() {
      if (this.isLoading) {
        return sprintf(
          __(
            'Loading files, directories, and submodules in the path %{path} for commit reference %{ref}',
          ),
          { path: this.path, ref: this.ref },
        );
      }

      return sprintf(
        __('Files, directories, and submodules in the path %{path} for commit reference %{ref}'),
        { path: this.path, ref: this.ref },
      );
    },
    showParentRow() {
      return ['', '/'].indexOf(this.path) === -1;
    },
  },
  watch: {
    $route: function routeChange() {
      this.$options.totalRowsLoaded = -1;
    },
  },
  totalRowsLoaded: -1,
  methods: {
    showMore() {
      this.$emit('showMore');
    },
    generateRowNumber(path, id, index) {
      const key = `${path}-${id}-${index}`;

      if (!this.rowNumbers[key] && this.rowNumbers[key] !== 0) {
        this.$options.totalRowsLoaded += 1;
        this.rowNumbers[key] = this.$options.totalRowsLoaded;
      }

      return this.rowNumbers[key];
    },
    getCommit(fileName) {
      return this.commits.find(
        (commitEntry) => commitEntry.filePath === joinPaths(this.path, fileName),
      );
    },
  },
};
</script>

<template>
  <div class="tree-content-holder">
    <div class="table-holder bordered-box">
      <table
        :aria-label="tableCaption"
        class="table tree-table"
        :class="{ 'gl-table-layout-fixed': !showParentRow }"
        aria-live="polite"
        data-qa-selector="file_tree_table"
      >
        <table-header v-once />
        <tbody>
          <parent-row
            v-if="showParentRow"
            :commit-ref="escapedRef"
            :path="path"
            :loading-path="loadingPath"
          />
          <template v-for="val in entries">
            <table-row
              v-for="(entry, index) in val"
              :id="entry.id"
              :key="`${entry.flatPath}-${entry.id}-${index}`"
              :sha="entry.sha"
              :project-path="projectPath"
              :current-path="path"
              :name="entry.name"
              :path="entry.flatPath"
              :type="entry.type"
              :url="entry.webUrl || entry.webPath"
              :mode="entry.mode"
              :submodule-tree-url="entry.treeUrl"
              :lfs-oid="entry.lfsOid"
              :loading-path="loadingPath"
              :total-entries="totalEntries"
              :row-number="generateRowNumber(entry.flatPath, entry.id, index)"
              :commit-info="getCommit(entry.name)"
              v-on="$listeners"
            />
          </template>
          <template v-if="isLoading">
            <tr v-for="i in 5" :key="i" aria-hidden="true">
              <td><gl-skeleton-loader :lines="1" /></td>
              <td class="gl-display-none gl-sm-display-block">
                <gl-skeleton-loader :lines="1" />
              </td>
              <td>
                <div class="gl-display-flex gl-lg-justify-content-end">
                  <gl-skeleton-loader :equal-width-lines="true" :lines="1" />
                </div>
              </td>
            </tr>
          </template>
          <template v-if="hasMore">
            <tr>
              <td align="center" colspan="3" class="gl-p-0!">
                <gl-button
                  variant="link"
                  class="gl-display-flex gl-w-full gl-py-4!"
                  :loading="isLoading"
                  @click="showMore"
                >
                  {{ s__('ProjectFileTree|Show more') }}
                </gl-button>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
