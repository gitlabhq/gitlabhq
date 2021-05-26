<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BranchSwitcher from './branch_switcher.vue';

export default {
  components: {
    BranchSwitcher,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    showBranchSwitcher() {
      return this.glFeatures.pipelineEditorBranchSwitcher;
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <branch-switcher v-if="showBranchSwitcher" v-on="$listeners" />
  </div>
</template>
