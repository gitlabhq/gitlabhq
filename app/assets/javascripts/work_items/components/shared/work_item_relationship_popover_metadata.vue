<script>
import { GlTooltipDirective, GlAvatarsInline, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import { s__, sprintf } from '~/locale';
import { WIDGET_TYPE_MILESTONE, WIDGET_TYPE_ASSIGNEES } from '~/work_items/constants';
import { findWidget } from '~/issues/list/utils';
import { getDisplayReference } from '../../utils';

export default {
  name: 'WorkItemRelationshipPopoverMetadata',
  components: {
    ItemMilestone,
    GlAvatar,
    GlAvatarLink,
    GlAvatarsInline,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
  },
  assigneesDisplayLimit: 3,
  computed: {
    workItemAssignees() {
      return findWidget(WIDGET_TYPE_ASSIGNEES, this.workItem)?.assignees?.nodes || [];
    },
    workItemMilestone() {
      return findWidget(WIDGET_TYPE_MILESTONE, this.workItem)?.milestone;
    },
    fullReference() {
      return getDisplayReference(this.workItemFullPath, this.workItem.reference);
    },
    directNamespaceReference() {
      return this.fullReference.split('/').slice(-1)[0];
    },
    assigneesCollapsedTooltip() {
      if (this.workItemAssignees.length > this.$options.assigneesDisplayLimit) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.workItemAssignees.length - this.$options.assigneesDisplayLimit,
        });
      }
      return '';
    },
  },
};
</script>

<template>
  <div
    class="shrink-0 gl-mt-1 gl-flex gl-w-fit gl-flex-wrap gl-items-center gl-gap-x-3 gl-gap-y-2 gl-text-sm gl-text-subtle"
  >
    <span v-gl-tooltip :title="fullReference">{{ directNamespaceReference }}</span>
    <slot name="weight-metadata"></slot>
    <item-milestone
      v-if="workItemMilestone"
      :milestone="workItemMilestone"
      class="gl-flex gl-max-w-15 !gl-cursor-help gl-items-center gl-gap-2 gl-leading-normal !gl-no-underline"
    />
    <slot name="additional-metadata"></slot>
    <gl-avatars-inline
      v-if="workItemAssignees.length"
      collapsed
      :avatars="workItemAssignees"
      :max-visible="$options.assigneesDisplayLimit"
      :avatar-size="16"
      badge-tooltip-prop="name"
      :badge-sr-only-text="assigneesCollapsedTooltip"
    >
      <template #avatar="{ avatar }">
        <gl-avatar-link v-gl-tooltip :href="avatar.webUrl" :title="avatar.name">
          <gl-avatar :alt="avatar.name" :src="avatar.avatarUrl" :size="16" />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
  </div>
</template>
