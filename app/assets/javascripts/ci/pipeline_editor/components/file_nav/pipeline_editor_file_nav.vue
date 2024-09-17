<script>
import { GlButton } from '@gitlab/ui';
import getAppStatus from '~/ci/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import { EDITOR_APP_STATUS_EMPTY, EDITOR_APP_STATUS_LOADING } from '../../constants';
import FileTreePopover from '../popovers/file_tree_popover.vue';
import BranchSwitcher from './branch_switcher.vue';

export default {
  components: {
    BranchSwitcher,
    FileTreePopover,
    GlButton,
  },
  props: {
    hasUnsavedChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldLoadNewBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
  },
  computed: {
    isAppLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
    showFileTreeToggle() {
      return !this.isNewCiConfigFile && this.appStatus !== EDITOR_APP_STATUS_EMPTY;
    },
  },
  methods: {
    onFileTreeBtnClick() {
      this.$emit('toggle-file-tree');
    },
  },
};
</script>
<template>
  <div class="gl-mb-4 gl-flex gl-flex-wrap gl-gap-3">
    <gl-button
      v-if="showFileTreeToggle"
      id="file-tree-toggle"
      icon="file-tree"
      data-testid="file-tree-toggle"
      :aria-label="__('File Tree')"
      :loading="isAppLoading"
      @click="onFileTreeBtnClick"
    />
    <file-tree-popover v-if="showFileTreeToggle" />
    <branch-switcher
      :has-unsaved-changes="hasUnsavedChanges"
      :should-load-new-branch="shouldLoadNewBranch"
      v-on="$listeners"
    />
  </div>
</template>
