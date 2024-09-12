<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { LINKED_CATEGORIES_MAP, sprintfWorkItem } from '../../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    linkedWorkItems: {
      type: Array,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  computed: {
    itemsBlockedBy() {
      return this.linkedWorkItems.filter((item) => {
        return item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY;
      });
    },
    itemsBlocks() {
      return this.linkedWorkItems.filter((item) => {
        return item.linkType === LINKED_CATEGORIES_MAP.BLOCKS;
      });
    },
    blockedByLabel() {
      const message = sprintf(
        n__(
          'WorkItem|%{workItemType} is blocked by 1 item',
          'WorkItem|%{workItemType} is blocked by %{itemCount} items',
          this.itemsBlockedBy.length,
        ),
        { itemCount: this.itemsBlockedBy.length },
      );
      return sprintfWorkItem(message, this.workItemType);
    },
    blocksLabel() {
      const message = sprintf(
        n__(
          'WorkItem|%{workItemType} blocks 1 item',
          'WorkItem|%{workItemType} blocks %{itemCount} items',
          this.itemsBlocks.length,
        ),
        { itemCount: this.itemsBlocks.length },
      );
      return sprintfWorkItem(message, this.workItemType);
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-gap-3">
    <span
      v-if="itemsBlockedBy.length"
      v-gl-tooltip
      :title="blockedByLabel"
      :aria-label="blockedByLabel"
      class="gl-text-sm gl-text-secondary"
      data-testid="relationship-blocked-by-icon"
    >
      <gl-icon name="entity-blocked" class="gl-text-red-500" />
      {{ itemsBlockedBy.length }}
    </span>
    <span
      v-if="itemsBlocks.length"
      v-gl-tooltip
      :title="blocksLabel"
      :aria-label="blocksLabel"
      class="gl-text-sm gl-text-secondary"
      data-testid="relationship-blocks-icon"
    >
      <gl-icon name="entity-blocking" class="gl-text-orange-500" />
      {{ itemsBlocks.length }}
    </span>
  </span>
</template>
