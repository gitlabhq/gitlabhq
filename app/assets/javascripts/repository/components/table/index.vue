<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf, __ } from '../../../locale';
import getRefMixin from '../../mixins/get_ref';
import getFiles from '../../queries/getFiles.graphql';
import TableHeader from './header.vue';

export default {
  components: {
    GlLoadingIcon,
    TableHeader,
  },
  mixins: [getRefMixin],
  apollo: {
    files: {
      query: getFiles,
      variables() {
        return {
          ref: this.ref,
          path: this.path,
        };
      },
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
      files: [],
    };
  },
  computed: {
    tableCaption() {
      return sprintf(
        __('Files, directories, and submodules in the path %{path} for commit reference %{ref}'),
        { path: this.path, ref: this.ref },
      );
    },
    isLoadingFiles() {
      return this.$apollo.queries.files.loading;
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
        <table-header />
        <tbody></tbody>
      </table>
      <gl-loading-icon v-if="isLoadingFiles" class="my-3" size="md" />
    </div>
  </div>
</template>
