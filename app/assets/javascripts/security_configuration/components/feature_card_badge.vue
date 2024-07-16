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
      :title="badge.tooltipText"
      :target="() => $refs.badge"
    />
    <span ref="badge">
      <gl-badge class="gl-cursor-pointer" :href="badgeHref" :variant="badge.variant">
        {{ badge.text }}
      </gl-badge>
    </span>
  </span>
</template>
