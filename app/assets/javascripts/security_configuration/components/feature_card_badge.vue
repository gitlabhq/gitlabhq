<script>
import { GlBadge, GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlTooltip,
  },
  props: {
    badge: {
      type: Object,
      required: true,
    },
    badgeHref: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <span>
    <gl-tooltip
      v-if="badge.tooltipText"
      placement="top"
      boundary="window"
      title="Tooltip title"
      :target="() => $refs.badge"
    >
      {{ badge.tooltipText }}
    </gl-tooltip>
    <span ref="badge">
      <gl-badge size="sm" :href="badgeHref" :variant="badge.variant">
        {{ badge.text }}
      </gl-badge>
    </span>
  </span>
</template>
