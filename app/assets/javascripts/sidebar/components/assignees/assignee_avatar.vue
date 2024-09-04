<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, sprintf } from '~/locale';

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
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
  },
  computed: {
    assigneeAlt() {
      return sprintf(__("%{userName}'s avatar"), { userName: this.user.name });
    },
    avatarUrl() {
      return (
        this.user.avatarUrl || this.user.avatar || this.user.avatar_url || gon.default_avatar_url
      );
    },
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    hasMergeIcon() {
      const canMerge = this.user.mergeRequestInteraction?.canMerge || this.user.can_merge;
      return this.isMergeRequest && !canMerge;
    },
  },
};
</script>

<template>
  <span class="gl-relative">
    <gl-avatar
      :label="user.name"
      :src="avatarUrl"
      :size="imgSize"
      :alt="assigneeAlt"
      data-testid="avatar-image"
    />
    <gl-icon v-if="hasMergeIcon" name="warning-solid" aria-hidden="true" class="merge-icon" />
  </span>
</template>
