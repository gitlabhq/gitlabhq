<script>
import { GlCard } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlCard,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    stageClasses: {
      type: String,
      required: false,
      default: '',
    },
    jobClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isNewPipelineGraph() {
      return this.glFeatures.newPipelineGraph;
    },
  },
};
</script>
<template>
  <div>
    <gl-card
      v-if="isNewPipelineGraph"
      class="gl-rounded-lg"
      header-class="gl-rounded-lg gl-px-0 gl-py-0 gl-bg-white gl-border-b-0"
      body-class="gl-pt-2 gl-pb-0 gl-px-2"
    >
      <template #header>
        <slot name="stages"></slot>
      </template>

      <slot name="jobs"></slot>
    </gl-card>
    <template v-else>
      <div class="gl-display-flex gl-align-items-center gl-w-full" :class="stageClasses">
        <slot name="stages"> </slot>
      </div>
      <div
        class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-w-full"
        :class="jobClasses"
      >
        <slot name="jobs"> </slot>
      </div>
    </template>
  </div>
</template>
