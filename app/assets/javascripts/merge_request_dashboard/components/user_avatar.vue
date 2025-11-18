<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';

const REVIEW_STATE_ICONS = {
  APPROVED: {
    name: 'check-circle',
    backgroundClass: 'gl-bg-status-success',
    foregroundClass: 'gl-fill-status-success',
  },
  REQUESTED_CHANGES: {
    name: 'error',
    backgroundClass: 'gl-bg-status-danger',
    foregroundClass: 'gl-fill-status-danger',
  },
  REVIEWED: {
    name: 'comment-lines',
    backgroundClass: 'gl-bg-status-info',
    foregroundClass: 'gl-fill-status-info',
  },
  REVIEW_STARTED: {
    name: 'comment-dots',
    backgroundClass: 'gl-bg-status-neutral',
    foregroundClass: 'gl-fill-status-neutral',
  },
};

export default {
  components: {
    GlAvatar,
    GlIcon,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
  computed: {
    reviewStateIcon() {
      return REVIEW_STATE_ICONS[this.user.mergeRequestInteraction?.reviewState];
    },
  },
};
</script>

<template>
  <span class="gl-relative">
    <gl-avatar
      :src="user.avatarUrl"
      :size="32"
      width="32"
      height="32"
      class="!gl-bg-subtle"
      loading="lazy"
    />
    <span
      v-if="reviewStateIcon"
      class="gl-absolute -gl-bottom-2 -gl-right-1 gl-flex gl-h-5 gl-w-5 gl-items-center gl-justify-center gl-rounded-full gl-p-1"
      :class="reviewStateIcon.backgroundClass"
      data-testid="review-state-icon"
    >
      <gl-icon
        :name="reviewStateIcon.name"
        class="gl-block"
        :class="reviewStateIcon.foregroundClass"
        :size="12"
      />
    </span>
  </span>
</template>
