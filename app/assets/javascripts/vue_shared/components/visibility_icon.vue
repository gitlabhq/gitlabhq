<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
  VISIBILITY_TYPE_ICON,
} from '~/visibility_level/constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isGroup: {
      default: false,
      required: false,
      type: Boolean,
    },
    tooltipPlacement: {
      default: 'top',
      required: false,
      type: String,
    },
    visibilityLevel: {
      required: true,
      type: String,
    },
  },
  computed: {
    isBannedProject() {
      return !this.isGroup && this.visibilityLevel === 'banned';
    },
    visibilityIcon() {
      return this.isBannedProject ? 'spam' : VISIBILITY_TYPE_ICON[this.visibilityLevel];
    },
    visibilityTooltip() {
      if (this.isBannedProject) {
        return __('This project is hidden because its creator has been banned');
      }

      if (this.isGroup) {
        return GROUP_VISIBILITY_TYPE[this.visibilityLevel];
      }

      return PROJECT_VISIBILITY_TYPE[this.visibilityLevel];
    },
  },
};
</script>

<template>
  <gl-icon
    v-gl-tooltip="{ placement: tooltipPlacement }"
    :aria-label="visibilityTooltip"
    :name="visibilityIcon"
    :title="visibilityTooltip"
    class="gl-inline-flex gl-text-secondary"
  />
</template>
