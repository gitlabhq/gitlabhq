<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    severity: {
      type: Object,
      required: true,
      validator(severity) {
        const { value, label, icon } = severity;
        return value && label && icon;
      },
    },
    iconSize: {
      type: Number,
      required: false,
      default: 12,
    },
    iconOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div
    class="incident-severity gl-display-inline-flex gl-align-items-center gl-justify-content-between"
  >
    <gl-icon
      :size="iconSize"
      :name="`severity-${severity.icon}`"
      :class="[`icon-${severity.icon}`, { 'gl-mr-3': !iconOnly }]"
    />
    <span v-if="!iconOnly">{{ severity.label }}</span>
  </div>
</template>
