<script>
import { GlButton } from '@gitlab/ui';
import getAppStatus from '~/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { EDITOR_APP_STATUS_EMPTY } from '../../constants';
import BranchSwitcher from './branch_switcher.vue';

export default {
  components: {
    BranchSwitcher,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
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
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
  },
  computed: {
    showFileTreeToggle() {
      return (
        this.glFeatures.pipelineEditorFileTree &&
        !this.isNewCiConfigFile &&
        this.appStatus !== EDITOR_APP_STATUS_EMPTY
      );
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
  <div class="gl-mb-4">
    <gl-button
      v-if="showFileTreeToggle"
      icon="file-tree"
      data-testid="file-tree-toggle"
      :aria-label="__('File Tree')"
      @click="onFileTreeBtnClick"
    />
    <branch-switcher
      :has-unsaved-changes="hasUnsavedChanges"
      :should-load-new-branch="shouldLoadNewBranch"
      v-on="$listeners"
    />
  </div>
</template>
