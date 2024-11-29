<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    icon: {
      type: String,
      required: false,
      default: '',
    },
    tooltip: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div v-gl-tooltip="tooltip" class="gl-mb-3 gl-mr-4 gl-inline-block gl-text-subtle">
    <gl-icon v-if="icon" :name="icon" :size="12" variant="subtle" />
    <!-- display tooltip as a label for screen readers and make it unavailable for copying -->
    <span class="gl-sr-only gl-select-none">{{ tooltip }}</span>
    <slot></slot>
  </div>
</template>
