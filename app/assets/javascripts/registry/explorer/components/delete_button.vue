<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';

export default {
  name: 'DeleteButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    tooltipTitle: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    tooltipDisabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    tooltipConfiguration() {
      return {
        disabled: this.tooltipDisabled,
        title: this.tooltipTitle,
      };
    },
  },
};
</script>

<template>
  <div v-gl-tooltip="tooltipConfiguration">
    <gl-button
      v-gl-tooltip
      :disabled="disabled"
      :title="title"
      :aria-label="title"
      variant="danger"
      category="secondary"
      icon="remove"
      @click="$emit('delete')"
    />
  </div>
</template>
