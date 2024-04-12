<script>
import { GlAvatarsInline, GlAvatar, GlAvatarLink, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

const AVATAR_TOOLTIP_MAX_CHARS = 100;
export const MAX_VISIBLE_AVATARS = 4;
export const AVATAR_SIZE = 32;

export default {
  name: 'ProtectionRow',
  AVATAR_TOOLTIP_MAX_CHARS,
  MAX_VISIBLE_AVATARS,
  AVATAR_SIZE,
  components: { GlAvatarsInline, GlAvatar, GlAvatarLink },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: null,
    },
    accessLevels: {
      type: Array,
      required: false,
      default: () => [],
    },
    showDivider: {
      type: Boolean,
      required: false,
      default: false,
    },
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    approvalsRequired: {
      type: Number,
      required: false,
      default: 0,
    },
    statusCheckUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    avatarBadgeSrOnlyText() {
      return n__(
        '%d additional user',
        '%d additional users',
        this.users.length - this.$options.MAX_VISIBLE_AVATARS,
      );
    },
    commaSeparateList() {
      return this.accessLevels.length > 1;
    },
    approvalsRequiredTitle() {
      return this.approvalsRequired
        ? n__('%d approval required', '%d approvals required', this.approvalsRequired)
        : null;
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-border-gray-100 gl-mb-4 gl-pt-4 gl-border-t-1"
    :class="{ 'gl-border-t-solid': showDivider }"
  >
    <div class="gl-display-flex gl-w-full gl-justify-content-space-between gl-align-items-center">
      <div class="gl-mr-7 gl-w-quarter">{{ title }}</div>

      <gl-avatars-inline
        v-if="users.length"
        class="gl-w-quarter!"
        :avatars="users"
        :collapsed="true"
        :max-visible="$options.MAX_VISIBLE_AVATARS"
        :avatar-size="$options.AVATAR_SIZE"
        badge-tooltip-prop="name"
        :badge-tooltip-max-chars="$options.AVATAR_TOOLTIP_MAX_CHARS"
        :badge-sr-only-text="avatarBadgeSrOnlyText"
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link
            :key="avatar.username"
            v-gl-tooltip
            target="_blank"
            :href="avatar.webUrl"
            :title="avatar.name"
          >
            <gl-avatar
              :src="avatar.avatarUrl"
              :label="avatar.name"
              :alt="avatar.name"
              :size="$options.AVATAR_SIZE"
            />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>

      <div v-if="statusCheckUrl" class="gl-ml-7 gl-flex-grow-1">{{ statusCheckUrl }}</div>

      <div
        v-for="(item, index) in accessLevels"
        :key="index"
        data-testid="access-level"
        :data-qa-role="item.accessLevelDescription"
      >
        <span v-if="commaSeparateList && index > 0" data-testid="comma-separator">,</span>
        {{ item.accessLevelDescription }}
      </div>

      <div class="gl-ml-7 gl-flex-grow-1">{{ approvalsRequiredTitle }}</div>
    </div>
  </div>
</template>
