<script>
import { GlIcon, GlAvatar, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime/timeago_utility';
import { n__ } from '~/locale';

export default {
  name: 'MergeRequestListItem',
  components: {
    GlIcon,
    GlAvatar,
    GlAvatarsInline,
  },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    formattedTime() {
      return getTimeago().format(this.mergeRequest.createdAt);
    },
    assignees() {
      const assignees = this.mergeRequest.assignees?.nodes;
      return assignees.length ? assignees : [this.mergeRequest.author];
    },
    assigneesBadgeSrOnlyText() {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        this.assignees.length - this.$options.MAX_VISIBLE_ASSIGNEES,
      );
    },
  },
  MAX_VISIBLE_ASSIGNEES: 3,
};
</script>

<template>
  <div class="gl-flex">
    <div class="gl-flex">
      <gl-icon name="merge-request" class="gl-mr-3 gl-flex-shrink-0" />
      <div class="gl-flex-grow">
        <div class="gl-mb-1 gl-mr-2 gl-line-clamp-2">
          {{ mergeRequest.title }}
        </div>
        <span class="gl-text-sm gl-text-secondary">
          {{ s__('OpenMrBadge|Opened') }} <time v-text="formattedTime"></time
        ></span>
      </div>
    </div>
    <div class="gl-ml-auto">
      <gl-avatars-inline
        :avatars="assignees"
        :collapsed="true"
        :avatar-size="24"
        :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
        :badge-sr-only-text="assigneesBadgeSrOnlyText"
      >
        <template #avatar="{ avatar }">
          <gl-avatar
            v-gl-tooltip
            :size="24"
            :src="avatar.avatarUrl"
            :alt="avatar.name"
            :title="avatar.name"
          />
        </template>
      </gl-avatars-inline>
    </div>
  </div>
</template>
