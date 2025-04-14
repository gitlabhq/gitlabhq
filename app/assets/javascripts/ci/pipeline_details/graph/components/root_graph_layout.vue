<script>
import { GlCard } from '@gitlab/ui';

export default {
  components: {
    GlCard,
  },
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
};
</script>
<template>
  <div>
    <gl-card
      class="ci-card gl-rounded-lg gl-bg-section"
      header-class="gl-rounded-t-lg gl-px-0 gl-pt-0 gl-pb-2 gl-bg-section gl-border-b-section"
      body-class="gl-pt-2 gl-pb-0 gl-px-0"
    >
      <template v-if="$scopedSlots.stages" #header>
        <slot name="stages"></slot>
      </template>

      <slot name="jobs"></slot>
    </gl-card>
  </div>
</template>
