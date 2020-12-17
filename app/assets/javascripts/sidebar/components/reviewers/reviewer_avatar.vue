<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: {
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
    reviewerAlt() {
      return sprintf(__("%{userName}'s avatar"), { userName: this.user.name });
    },
    avatarUrl() {
      return this.user.avatar || this.user.avatar_url || gon.default_avatar_url;
    },
    hasMergeIcon() {
      return !this.user.can_merge;
    },
  },
};
</script>

<template>
  <span class="position-relative">
    <img
      :alt="reviewerAlt"
      :src="avatarUrl"
      :width="imgSize"
      :class="`s${imgSize}`"
      class="avatar avatar-inline m-0"
      data-qa-selector="avatar_image"
    />
    <gl-icon v-if="hasMergeIcon" name="warning-solid" aria-hidden="true" class="merge-icon" />
  </span>
</template>
