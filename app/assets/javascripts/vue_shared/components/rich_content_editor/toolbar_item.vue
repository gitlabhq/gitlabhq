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
      required: true,
    },
    tooltip: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <button
    v-gl-tooltip="{ title: tooltip }"
    :aria-label="tooltip"
    class="p-0 gl-display-flex toolbar-button"
  >
    <gl-icon class="gl-mx-auto gl-align-self-center" :name="icon" />
  </button>
</template>
