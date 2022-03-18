<script>
import { GlAvatarLabeled, GlAvatarLink, GlIcon } from '@gitlab/ui';
import { IssuableType } from '~/issues/constants';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlIcon,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: IssuableType.Issue,
    },
  },
  computed: {
    userLabel() {
      if (!this.user.status) {
        return this.user.name;
      }
      return sprintf(s__('UserAvailability|%{author} (Busy)'), {
        author: this.user.name,
      });
    },
    hasCannotMergeIcon() {
      return this.issuableType === IssuableType.MergeRequest && !this.user.canMerge;
    },
  },
};
</script>

<template>
  <gl-avatar-link>
    <gl-avatar-labeled
      :size="32"
      :label="userLabel"
      :sub-label="`@${user.username}`"
      :src="user.avatarUrl || user.avatar || user.avatar_url"
      class="gl-align-items-center gl-relative"
    >
      <template #meta>
        <gl-icon
          v-if="hasCannotMergeIcon"
          name="warning-solid"
          aria-hidden="true"
          class="merge-icon"
          :size="12"
        />
      </template>
    </gl-avatar-labeled>
  </gl-avatar-link>
</template>
