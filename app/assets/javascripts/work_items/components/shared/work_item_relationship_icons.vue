<script>
import { GlIcon } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { LINKED_CATEGORIES_MAP, sprintfWorkItem } from '../../constants';
import workItemLinkedItemsQuery from '../../graphql/work_item_linked_items.query.graphql';
import { findLinkedItemsWidget } from '../../utils';
import WorkItemRelationshipPopover from './work_item_relationship_popover.vue';

export default {
  components: {
    GlIcon,
    WorkItemRelationshipPopover,
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
    workItemWebUrl: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
  },
  apollo: {
    childItemLinkedItems: {
      skip() {
        return this.skipQuery;
      },
      query() {
        return workItemLinkedItemsQuery;
      },
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update({ workspace }) {
        if (!workspace?.workItem) return [];

        this.skipQuery = true;
        return findLinkedItemsWidget(workspace.workItem).linkedItems?.nodes || [];
      },
    },
  },
  data() {
    return {
      skipQuery: true,
      childItemLinkedItems: [],
    };
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
    itemsBlockedByIconId() {
      return `relationship-blocked-by-icon-${this.workItemIid}`;
    },
    itemsBlocksIconId() {
      return `relationship-blocks-icon-${this.workItemIid}`;
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
    isLoading() {
      return this.$apollo.queries.childItemLinkedItems.loading;
    },
    childBlockedByItems() {
      return this.childItemLinkedItems.filter((item) => {
        return item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY;
      });
    },
    childBlocksItems() {
      return this.childItemLinkedItems.filter((item) => {
        return item.linkType === LINKED_CATEGORIES_MAP.BLOCKS;
      });
    },
  },
  methods: {
    handleMouseEnter() {
      this.skipQuery = false;
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-gap-3">
    <template v-if="itemsBlockedBy.length > 0">
      <span
        :id="itemsBlockedByIconId"
        :aria-label="blockedByLabel"
        tabIndex="0"
        class="gl-cursor-pointer gl-text-sm gl-text-subtle"
        data-testid="relationship-blocked-by-icon"
        @mouseenter="handleMouseEnter"
      >
        <gl-icon name="entity-blocked" variant="danger" />
        {{ itemsBlockedBy.length }}
      </span>
      <work-item-relationship-popover
        :target="itemsBlockedByIconId"
        :title="s__('WorkItem|Blocked by')"
        :loading="isLoading"
        :linked-work-items="childBlockedByItems"
        :work-item-full-path="workItemFullPath"
        :work-item-web-url="workItemWebUrl"
        :work-item-type="workItemType"
      />
    </template>

    <template v-if="itemsBlocks.length > 0">
      <span
        :id="itemsBlocksIconId"
        :aria-label="blocksLabel"
        tabIndex="0"
        class="gl-cursor-pointer gl-text-sm gl-text-subtle"
        data-testid="relationship-blocks-icon"
        @mouseenter="handleMouseEnter"
      >
        <gl-icon name="entity-blocking" variant="warning" />
        {{ itemsBlocks.length }}
      </span>
      <work-item-relationship-popover
        :target="itemsBlocksIconId"
        :title="s__('WorkItem|Blocking')"
        :loading="isLoading"
        :linked-work-items="childBlocksItems"
        :work-item-full-path="workItemFullPath"
        :work-item-web-url="workItemWebUrl"
        :work-item-type="workItemType"
      />
    </template>
  </span>
</template>
