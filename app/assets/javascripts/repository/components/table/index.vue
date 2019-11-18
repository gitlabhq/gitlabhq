<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import { sprintf, __ } from '../../../locale';
import getRefMixin from '../../mixins/get_ref';
import getProjectPath from '../../queries/getProjectPath.query.graphql';
import TableHeader from './header.vue';
import TableRow from './row.vue';
import ParentRow from './parent_row.vue';

export default {
  components: {
    GlSkeletonLoading,
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
    entries: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
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
      return !this.isLoading && ['', '/'].indexOf(this.path) === -1;
    },
  },
};
</script>

<template>
  <div class="tree-content-holder">
    <div class="table-holder bordered-box">
      <table :aria-label="tableCaption" class="table tree-table qa-file-tree" aria-live="polite">
        <table-header v-once />
        <tbody>
          <parent-row v-show="showParentRow" :commit-ref="ref" :path="path" />
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
              :url="entry.webUrl"
              :submodule-tree-url="entry.treeUrl"
              :lfs-oid="entry.lfsOid"
            />
          </template>
          <template v-if="isLoading">
            <tr v-for="i in 5" :key="i" aria-hidden="true">
              <td><gl-skeleton-loading :lines="1" class="h-auto" /></td>
              <td><gl-skeleton-loading :lines="1" class="h-auto" /></td>
              <td><gl-skeleton-loading :lines="1" class="ml-auto h-auto w-50" /></td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
