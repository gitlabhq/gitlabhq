<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { __, sprintf } from '~/locale';

export default {
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
    <i v-if="hasMergeIcon" aria-hidden="true" class="fa fa-exclamation-triangle merge-icon"></i>
  </span>
</template>
