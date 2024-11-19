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
      class="gl-rounded-lg gl-bg-section"
      header-class="gl-rounded-lg gl-px-0 gl-py-0 gl-bg-section gl-border-b-0"
      body-class="gl-pt-2 gl-pb-0 gl-px-2"
    >
      <template #header>
        <slot name="stages"></slot>
      </template>

      <slot name="jobs"></slot>
    </gl-card>
  </div>
</template>
