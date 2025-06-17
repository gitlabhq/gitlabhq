<script>
import { GlIcon } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { LINKED_CATEGORIES_MAP, sprintfWorkItem, STATE_OPEN } from '../../constants';
import workItemLinkedItemsSlimQuery from '../../graphql/work_items_linked_items_slim.query.graphql';
import { findLinkedItemsWidget } from '../../utils';
import WorkItemRelationshipPopover from './work_item_relationship_popover.vue';

export default {
  name: 'WorkItemRelationshipIcons',
  components: {
    GlIcon,
    WorkItemRelationshipPopover,
  },
  props: {
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
    targetId: {
      type: String,
      required: false,
      default: '',
    },
    blockingCount: {
      type: Number,
      required: false,
      default: 0,
    },
    blockedByCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      loadingItems: true,
      childItemLinkedItems: [],
      activePopoverType: null,
    };
  },
  apollo: {
    childItemLinkedItems: {
      skip() {
        return this.loadingItems;
      },
      query() {
        return workItemLinkedItemsSlimQuery;
      },
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update({ workspace }) {
        if (!workspace?.workItem) return [];

        return findLinkedItemsWidget(workspace.workItem).linkedItems?.nodes || [];
      },
    },
  },
  computed: {
    itemsBlockedByIconId() {
      return `relationship-blocked-by-icon-${this.targetId || this.workItemIid}`;
    },
    itemsBlocksIconId() {
      return `relationship-blocks-icon-${this.targetId || this.workItemIid}`;
    },
    blockedByLabel() {
      const message = sprintf(
        n__(
          'WorkItem|%{workItemType} is blocked by 1 item',
          'WorkItem|%{workItemType} is blocked by %{itemCount} items',
          this.blockedByCount,
        ),
        { itemCount: this.blockedByCount },
      );
      return sprintfWorkItem(message, this.workItemType);
    },
    blocksLabel() {
      const message = sprintf(
        n__(
          'WorkItem|%{workItemType} blocks 1 item',
          'WorkItem|%{workItemType} blocks %{itemCount} items',
          this.blockingCount,
        ),
        { itemCount: this.blockingCount },
      );
      return sprintfWorkItem(message, this.workItemType);
    },
    blockedByItems() {
      return this.childItemLinkedItems.filter(
        (item) =>
          item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY &&
          item.workItem.state === STATE_OPEN,
      );
    },
    blockingItems() {
      return this.childItemLinkedItems.filter(
        (item) =>
          item.linkType === LINKED_CATEGORIES_MAP.BLOCKS && item.workItem.state === STATE_OPEN,
      );
    },
  },
  methods: {
    handleBlockedByMouseEnter() {
      this.activePopoverType = 'blockedBy';
      this.loadingItems = false;
    },
    handleBlocksMouseEnter() {
      this.activePopoverType = 'blocks';
      this.loadingItems = false;
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-gap-3">
    <template v-if="blockedByCount > 0">
      <span
        :id="itemsBlockedByIconId"
        :aria-label="blockedByLabel"
        tabIndex="0"
        class="gl-cursor-pointer gl-text-sm gl-text-subtle"
        data-testid="relationship-blocked-by-icon"
        @mouseenter="handleBlockedByMouseEnter"
      >
        <gl-icon name="entity-blocked" variant="danger" />
        {{ blockedByCount }}
      </span>
      <work-item-relationship-popover
        :target="itemsBlockedByIconId"
        :title="blockedByLabel"
        :linked-work-items="blockedByItems"
        :work-item-full-path="workItemFullPath"
        :work-item-type="workItemType"
        :work-item-web-url="workItemWebUrl"
        placement="bottom"
        data-testid="work-item-blocked-by-popover"
      />
    </template>

    <template v-if="blockingCount > 0">
      <span
        :id="itemsBlocksIconId"
        :aria-label="blocksLabel"
        tabIndex="0"
        class="gl-cursor-pointer gl-text-sm gl-text-subtle"
        data-testid="relationship-blocks-icon"
        @mouseenter="handleBlocksMouseEnter"
      >
        <gl-icon name="entity-blocking" variant="warning" />
        {{ blockingCount }}
      </span>
      <work-item-relationship-popover
        :target="itemsBlocksIconId"
        :title="blocksLabel"
        :linked-work-items="blockingItems"
        :work-item-full-path="workItemFullPath"
        :work-item-type="workItemType"
        :work-item-web-url="workItemWebUrl"
        placement="bottom"
        data-testid="work-item-blocks-popover"
      />
    </template>
  </span>
</template>
