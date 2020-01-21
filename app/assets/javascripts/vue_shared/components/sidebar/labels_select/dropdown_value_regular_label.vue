<script>
import { GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
  },
  props: {
    label: {
      type: Object,
      required: true,
    },
    labelStyle: {
      type: Object,
      required: true,
    },
    labelFilterUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <a ref="regularLabelRef" :href="labelFilterUrl">
    <span :style="labelStyle" class="badge color-label">
      {{ label.title }}
    </span>
    <gl-tooltip :target="() => $refs.regularLabelRef" placement="top" boundary="viewport">
      {{ label.description }}
    </gl-tooltip>
  </a>
</template>
