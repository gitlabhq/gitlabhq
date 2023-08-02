<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  components: {
    GlIcon,
    TooltipOnTruncate,
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
    class="incident-severity gl-display-inline-flex gl-align-items-center gl-justify-content-between gl-max-w-full"
  >
    <gl-icon
      :size="iconSize"
      :name="`severity-${severity.icon}`"
      :class="[`icon-${severity.icon}`, { 'gl-mr-3 gl-flex-shrink-0': !iconOnly }]"
    />
    <tooltip-on-truncate v-if="!iconOnly" :title="severity.label" class="gl-text-truncate">
      {{ severity.label }}
    </tooltip-on-truncate>
  </div>
</template>
