<script>
import { GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { TREE_ITEM_KIND_ICONS, TREE_ITEM_STATUS_ICONS } from '~/environments/constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip,
  },
  props: {
    kind: {
      required: true,
      type: String,
    },
    name: {
      required: true,
      type: String,
    },
    status: {
      required: false,
      type: String,
      default: '',
    },
  },
  computed: {
    statusBadge() {
      return TREE_ITEM_STATUS_ICONS[this.status] || TREE_ITEM_STATUS_ICONS.unknown;
    },
    kindIcon() {
      return TREE_ITEM_KIND_ICONS[this.kind];
    },
  },
};
</script>
<template>
  <div
    class="gl-rounded gl-relative gl-z-1 gl-flex gl-w-28 gl-border-1 gl-border-solid gl-border-strong gl-bg-white gl-p-3"
  >
    <gl-icon :name="kindIcon" data-testid="resource-kind-icon" />
    <div class="gl-ml-4">
      <span class="gl-mb-2 gl-block gl-text-subtle">{{ kind }}:</span>
      <div class="gl-flex gl-items-center">
        <span class="gl-line-clamp-1 gl-break-all" :title="name">{{ name }}</span>
        <gl-icon
          v-if="status"
          v-gl-tooltip
          :title="status"
          :name="statusBadge.icon"
          :size="12"
          :variant="statusBadge.variant"
          class="gl-ml-2"
          data-testid="resource-status-icon"
        />
      </div>
    </div>
  </div>
</template>
