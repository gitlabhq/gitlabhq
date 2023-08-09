<script>
import { GlAvatar, GlAvatarLink, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';

import { WIDGET_TYPE_MILESTONE, WIDGET_TYPE_ASSIGNEES } from '../../constants';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
    GlAvatarsInline,
    ItemMilestone,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    metadataWidgets: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    milestone() {
      return this.metadataWidgets[WIDGET_TYPE_MILESTONE]?.milestone;
    },
    assignees() {
      return this.metadataWidgets[WIDGET_TYPE_ASSIGNEES]?.assignees?.nodes || [];
    },
    assigneesCollapsedTooltip() {
      if (this.assignees.length > 2) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.assignees.length - 2,
        });
      }
      return '';
    },
    assigneesContainerClass() {
      if (this.assignees.length === 2) {
        return 'fixed-width-avatars-2';
      } else if (this.assignees.length > 2) {
        return 'fixed-width-avatars-3';
      }
      return '';
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-md-justify-content-end gl-gap-3">
    <slot></slot>
    <item-milestone
      v-if="milestone"
      :milestone="milestone"
      class="gl-display-flex gl-align-items-center gl-max-w-15 gl-font-sm gl-line-height-normal gl-text-secondary! gl-cursor-help! gl-text-decoration-none!"
    />
    <gl-avatars-inline
      v-if="assignees.length"
      :avatars="assignees"
      :collapsed="true"
      :max-visible="2"
      :avatar-size="24"
      badge-tooltip-prop="name"
      :badge-sr-only-text="assigneesCollapsedTooltip"
      :class="assigneesContainerClass"
    >
      <template #avatar="{ avatar }">
        <gl-avatar-link v-gl-tooltip target="blank" :href="avatar.webUrl" :title="avatar.name">
          <gl-avatar :src="avatar.avatarUrl" :size="24" />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
  </div>
</template>

<style scoped>
/**
 * These overrides are needed to address https://gitlab.com/gitlab-org/gitlab-ui/-/issues/865
 */
.fixed-width-avatars-2 {
  width: 42px !important;
}

.fixed-width-avatars-3 {
  width: 67px !important;
}
</style>
