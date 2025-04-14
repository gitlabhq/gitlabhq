<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
  VISIBILITY_TYPE_ICON,
} from '~/visibility_level/constants';

export default {
  components: {
    GlIcon,
    GlButton,
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
  <gl-button
    v-gl-tooltip="{ title: visibilityTooltip, placement: tooltipPlacement, boundary: 'viewport' }"
    :aria-label="visibilityTooltip"
    category="tertiary"
    size="small"
    class="!gl-min-h-5 !gl-min-w-5 !gl-p-0"
  >
    <gl-icon variant="subtle" :name="visibilityIcon" />
  </gl-button>
</template>
