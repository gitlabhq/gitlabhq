<script>
import { GlAvatarLabeled, GlBadge, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __ } from '~/locale';

const AVAILABILITY_STATUS = {
  NOT_SET: 'NOT_SET',
  BUSY: 'BUSY',
};

export default {
  components: {
    GlAvatarLabeled,
    GlBadge,
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
      default: TYPE_ISSUE,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isBusy() {
      return this.user?.status?.availability === AVAILABILITY_STATUS.BUSY;
    },
    hasCannotMergeIcon() {
      return this.issuableType === TYPE_MERGE_REQUEST && !this.user.canMerge;
    },
  },
  i18n: {
    busy: __('Busy'),
  },
};
</script>

<template>
  <gl-avatar-labeled
    :size="32"
    :label="user.name"
    :sub-label="`@${user.username}`"
    :src="user.avatarUrl || user.avatar || user.avatar_url"
    class="sidebar-participant gl-relative gl-items-center"
  >
    <template #meta>
      <gl-icon
        v-if="hasCannotMergeIcon"
        name="warning-solid"
        aria-hidden="true"
        class="merge-icon"
        :class="{ '!gl-left-6': selected }"
        :size="12"
      />
      <gl-badge v-if="isBusy" variant="warning" class="gl-ml-2">
        {{ $options.i18n.busy }}
      </gl-badge>
    </template>
  </gl-avatar-labeled>
</template>
