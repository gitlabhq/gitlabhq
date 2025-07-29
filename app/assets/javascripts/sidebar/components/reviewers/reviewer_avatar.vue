<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlAvatar, GlIcon } from '@gitlab/ui';

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
    imgSize: {
      type: Number,
      required: true,
    },
  },
  computed: {
    avatarUrl() {
      return this.user.avatarUrl || this.user.avatar_url || gon.default_avatar_url;
    },
    hasMergeIcon() {
      return !this.user.mergeRequestInteraction?.canMerge;
    },
  },
};
</script>

<template>
  <span class="gl-relative">
    <gl-avatar :label="user.name" :src="avatarUrl" :size="imgSize" aria-hidden="true" />
    <gl-icon
      v-if="hasMergeIcon"
      :aria-label="__('Cannot merge')"
      name="warning-solid"
      class="merge-icon reviewer-merge-icon"
    />
  </span>
</template>
