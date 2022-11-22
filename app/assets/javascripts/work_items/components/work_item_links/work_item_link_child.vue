<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import { STATE_OPEN } from '../../constants';
import WorkItemLinksMenu from './work_item_links_menu.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    RichTimestampTooltip,
    WorkItemLinksMenu,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
    issuableGid: {
      type: String,
      required: true,
    },
    childItem: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isItemOpen() {
      return this.childItem.state === STATE_OPEN;
    },
    iconClass() {
      return this.isItemOpen ? 'gl-text-green-500' : 'gl-text-blue-500';
    },
    iconName() {
      return this.isItemOpen ? 'issue-open-m' : 'issue-close';
    },
    stateTimestamp() {
      return this.isItemOpen ? this.childItem.createdAt : this.childItem.closedAt;
    },
    stateTimestampTypeText() {
      return this.isItemOpen ? __('Created') : __('Closed');
    },
    childPath() {
      return `/${this.projectPath}/-/work_items/${getIdFromGraphQLId(this.childItem.id)}`;
    },
  },
};
</script>

<template>
  <div
    class="gl-relative gl-display-flex gl-overflow-break-word gl-min-w-0 gl-bg-white gl-mb-3 gl-py-3 gl-px-4 gl-border gl-border-gray-100 gl-rounded-base gl-line-height-32"
    data-testid="links-child"
  >
    <div class="gl-overflow-hidden gl-display-flex gl-align-items-center gl-flex-grow-1">
      <span :id="`stateIcon-${childItem.id}`" class="gl-mr-3" data-testid="item-status-icon">
        <gl-icon :name="iconName" :class="iconClass" :aria-label="stateTimestampTypeText" />
      </span>
      <rich-timestamp-tooltip
        :target="`stateIcon-${childItem.id}`"
        :raw-timestamp="stateTimestamp"
        :timestamp-type-text="stateTimestampTypeText"
      />
      <gl-icon
        v-if="childItem.confidential"
        v-gl-tooltip.top
        name="eye-slash"
        class="gl-mr-2 gl-text-orange-500"
        data-testid="confidential-icon"
        :aria-label="__('Confidential')"
        :title="__('Confidential')"
      />
      <gl-button
        :href="childPath"
        category="tertiary"
        variant="link"
        class="gl-text-truncate gl-max-w-80 gl-text-black-normal!"
        @click="$emit('click', $event)"
        @mouseover="$emit('mouseover')"
        @mouseout="$emit('mouseout')"
      >
        {{ childItem.title }}
      </gl-button>
    </div>
    <div
      v-if="canUpdate"
      class="gl-ml-0 gl-sm-ml-auto! gl-display-inline-flex gl-align-items-center"
    >
      <work-item-links-menu
        :work-item-id="childItem.id"
        :parent-work-item-id="issuableGid"
        data-testid="links-menu"
        @removeChild="$emit('remove', childItem.id)"
      />
    </div>
  </div>
</template>
