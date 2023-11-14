<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  mixins: [glFeatureFlagMixin()],
  computed: {
    isNewPipelineGraph() {
      return this.glFeatures.newPipelineGraph;
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex"
    :class="{ 'gl-flex-wrap gl-sm-flex-nowrap gl-w-full': isNewPipelineGraph }"
  >
    <slot name="upstream"></slot>
    <slot name="main"></slot>
    <slot name="downstream"></slot>
  </div>
</template>
