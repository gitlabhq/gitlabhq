<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
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
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibilityLevel];
    },
    visibilityTooltip() {
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
    class="gl-display-inline-flex gl-text-secondary"
  />
</template>
