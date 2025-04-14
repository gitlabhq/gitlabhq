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
  <div v-gl-tooltip="tooltip" class="gl-flex gl-items-start gl-gap-2 gl-text-subtle">
    <gl-icon v-if="icon" :name="icon" :size="12" variant="subtle" class="gl-mt-1 gl-shrink-0" />
    <!-- display tooltip as a label for screen readers and make it unavailable for copying -->
    <span class="gl-sr-only gl-select-none">{{ tooltip }}</span>
    <slot></slot>
  </div>
</template>
