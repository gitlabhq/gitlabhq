<script>
import { GlPopover, GlLoadingIcon, GlTooltipDirective, GlLink } from '@gitlab/ui';
import { n__ } from '~/locale';
import { WORK_ITEM_TYPE_VALUE_ISSUE, STATE_CLOSED } from '~/work_items/constants';
import WorkItemRelationshipPopoverMetadata from 'ee_else_ce/work_items/components/shared/work_item_relationship_popover_metadata.vue';
import WorkItemTypeIcon from '../work_item_type_icon.vue';

const defaultDisplayLimit = 3;

export default {
  components: {
    GlPopover,
    GlLoadingIcon,
    GlLink,
    WorkItemTypeIcon,
    WorkItemRelationshipPopoverMetadata,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    linkedWorkItems: {
      type: Array,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    target: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
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
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  defaultDisplayLimit: 3,
  computed: {
    atLinkedItemsDisplayLimit() {
      return this.linkedWorkItems.length > defaultDisplayLimit;
    },
    displayedIssuablesCount() {
      return this.atLinkedItemsDisplayLimit
        ? this.linkedWorkItems.length - defaultDisplayLimit
        : this.linkedWorkItems.length;
    },
    moreItemsText() {
      return n__('WorkItem|+%d more item', 'WorkItem|+%d more items', this.displayedIssuablesCount);
    },
    linkedItemsToDisplay() {
      // Filtering closed child linked items and cutting to deafult display amount
      return this.linkedWorkItems
        .filter((item) => {
          return item.workItemState !== STATE_CLOSED;
        })
        .slice(0, defaultDisplayLimit);
    },
    moreItemsLink() {
      return `${this.workItemWebUrl}#${this.workItemType === WORK_ITEM_TYPE_VALUE_ISSUE ? 'related-issues' : 'linkeditems'}`;
    },
  },
};
</script>

<template>
  <gl-popover
    :target="target"
    placement="top"
    triggers="hover focus"
    :css-classes="['gl-max-w-sm']"
  >
    <template #title>
      <span class="gl-text-sm gl-text-subtle">{{ title }}</span>
    </template>
    <gl-loading-icon v-if="loading" size="sm" />

    <template v-else>
      <ul
        class="gl-mb-0 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-p-0"
        :class="{ 'gl-mb-3': atLinkedItemsDisplayLimit }"
      >
        <li v-for="{ workItem } in linkedItemsToDisplay" :key="workItem.id">
          <work-item-type-icon
            :show-tooltip-on-hover="true"
            class="gl-mr-1 gl-cursor-help"
            icon-variant="subtle"
            :work-item-type="workItem.workItemType.name"
          />
          <gl-link
            :href="workItem.webUrl"
            class="gl-link gl-hyphens-auto gl-break-words gl-text-base gl-font-semibold gl-text-default hover:gl-text-default"
            @click.exact="$emit('click', $event)"
            @mouseover="$emit('mouseover')"
            @mouseout="$emit('mouseout')"
          >
            {{ workItem.title }}
          </gl-link>
          <work-item-relationship-popover-metadata
            :work-item="workItem"
            :work-item-full-path="workItemFullPath"
          />
        </li>
      </ul>
      <gl-link
        v-if="atLinkedItemsDisplayLimit"
        data-testid="more-related-items-link"
        :href="moreItemsLink"
        class="gl-mt-3 gl-text-sm !gl-text-blue-500"
        >{{ moreItemsText }}</gl-link
      >
    </template>
  </gl-popover>
</template>
