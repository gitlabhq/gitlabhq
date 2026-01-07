<script>
import { GlAvatarLabeled, GlBadge, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, s__ } from '~/locale';

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
    isAgent() {
      return this.user?.compositeIdentityEnforced;
    },
    isDisabled() {
      return this.user?.status?.disabledForDuoUsage === true;
    },
    disabledReason() {
      return this.user?.status?.disabledForDuoUsageReason || s__('WorkItem|Cannot be assigned');
    },
    hasCannotMergeIcon() {
      return this.issuableType === TYPE_MERGE_REQUEST && !this.user.canMerge;
    },
    subLabel() {
      return this.isDisabled ? this.disabledReason : `@${this.user.username}`;
    },
  },
  i18n: {
    busy: __('Busy'),
    agent: __('AI'),
  },
};
</script>

<template>
  <gl-avatar-labeled
    :size="32"
    :label="user.name"
    :sub-label="subLabel"
    :is-disabled="isDisabled"
    :src="user.avatarUrl || user.avatar || user.avatar_url"
    class="sidebar-participant gl-relative gl-items-center"
    :class="{ 'sidebar-participant-disabled': isDisabled }"
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
    </template>
    <div class="gl-mt-2 gl-gap-1">
      <gl-badge v-if="isBusy" variant="warning" data-testid="busy-badge">
        {{ $options.i18n.busy }}
      </gl-badge>
      <gl-badge v-if="isAgent" variant="neutral" data-testid="sidebar-participant-agent-badge">
        {{ $options.i18n.agent }}
      </gl-badge>
    </div>
  </gl-avatar-labeled>
</template>
