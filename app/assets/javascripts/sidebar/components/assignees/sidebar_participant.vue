<script>
import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { IssuableType } from '~/issues/constants';
import { s__, sprintf } from '~/locale';

const AVAILABILITY_STATUS = {
  NOT_SET: 'NOT_SET',
  BUSY: 'BUSY',
};

export default {
  components: {
    GlAvatarLabeled,
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
      const { name, status } = this.user;
      if (!status || status?.availability !== AVAILABILITY_STATUS.BUSY) {
        return name;
      }
      return sprintf(
        s__('UserAvailability|%{author} (Busy)'),
        {
          author: name,
        },
        false,
      );
    },
    hasCannotMergeIcon() {
      return this.issuableType === IssuableType.MergeRequest && !this.user.canMerge;
    },
  },
};
</script>

<template>
  <gl-avatar-labeled
    :size="32"
    :label="userLabel"
    :sub-label="`@${user.username}`"
    :src="user.avatarUrl || user.avatar || user.avatar_url"
    class="gl-align-items-center gl-relative sidebar-participant"
  >
    <template #meta>
      <gl-icon
        v-if="hasCannotMergeIcon"
        name="warning-solid"
        aria-hidden="true"
        class="merge-icon gl-left-6 gl-bottom-0"
        :size="12"
      />
    </template>
  </gl-avatar-labeled>
</template>
