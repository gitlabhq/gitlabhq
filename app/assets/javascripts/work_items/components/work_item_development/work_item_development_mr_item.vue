<script>
import {
  GlLink,
  GlIcon,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { STATUS_OPEN, STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';

export default {
  components: {
    GlLink,
    GlIcon,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    itemContent: {
      type: Object,
      required: true,
    },
  },
  computed: {
    assignees() {
      return this.itemContent?.assignees?.nodes || [];
    },
    stateIconClass() {
      return {
        'gl-text-green-500': this.itemContent.state === STATUS_OPEN,
        'gl-text-red-500': this.itemContent.state === STATUS_CLOSED,
        'gl-text-blue-500': this.itemContent.state === STATUS_MERGED,
      };
    },
    stateIcon() {
      const stateIcons = {
        [STATUS_OPEN]: 'merge-request',
        [STATUS_MERGED]: 'merge',
        [STATUS_CLOSED]: 'merge-request-close',
      };
      return stateIcons[this.itemContent.state];
    },
    assigneesCollapsedTooltip() {
      if (this.assignees.length > 2) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.assignees.length - 2,
        });
      }
      return '';
    },
    projectPath() {
      return `${this.itemContent.project.namespace.path}/${this.itemContent.project.name}`;
    },
  },
};
</script>
<template>
  <div class="gl-mb-2 gl-flex gl-items-center gl-justify-between gl-gap-2">
    <gl-link
      :href="itemContent.webUrl"
      class="gfm-merge_request gl-truncate gl-text-gray-900 hover:gl-text-gray-900 hover:gl-underline"
      data-reference-type="merge_request"
      :data-project-path="projectPath"
      :data-iid="itemContent.iid"
      :data-mr-title="itemContent.title"
      data-placement="left"
    >
      <gl-icon :name="stateIcon" :class="stateIconClass" /> {{ itemContent.title }}
    </gl-link>
    <gl-avatars-inline
      v-if="assignees.length"
      :avatars="assignees"
      collapsed
      :max-visible="1"
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
