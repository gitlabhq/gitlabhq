<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlButton } from '@gitlab/ui';
import { sprintf, __ } from '../../../locale';
import getRefMixin from '../../mixins/get_ref';
import projectPathQuery from '../../queries/project_path.query.graphql';
import TableHeader from './header.vue';
import ParentRow from './parent_row.vue';
import TableRow from './row.vue';

export default {
  components: {
    GlSkeletonLoading,
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
  methods: {
    showMore() {
      this.$emit('showMore');
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
              v-for="entry in val"
              :id="entry.id"
              :key="`${entry.flatPath}-${entry.id}`"
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
            />
          </template>
          <template v-if="isLoading">
            <tr v-for="i in 5" :key="i" aria-hidden="true">
              <td><gl-skeleton-loading :lines="1" class="h-auto" /></td>
              <td><gl-skeleton-loading :lines="1" class="h-auto" /></td>
              <td><gl-skeleton-loading :lines="1" class="ml-auto h-auto w-50" /></td>
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
