<script>
import {
  GlAvatarsInline,
  GlAvatar,
  GlAvatarLink,
  GlTooltipDirective,
  GlBadge,
  GlIcon,
} from '@gitlab/ui';
import { n__, __ } from '~/locale';
import { accessLevelsConfig } from './constants';

const AVATAR_TOOLTIP_MAX_CHARS = 100;
export const MAX_VISIBLE_AVATARS = 4;
export const AVATAR_SIZE = 24;

export default {
  i18n: {
    sharedSecret: __('HMAC enabled'),
  },
  name: 'ProtectionRow',
  AVATAR_TOOLTIP_MAX_CHARS,
  MAX_VISIBLE_AVATARS,
  AVATAR_SIZE,
  accessLevelsConfig,
  components: { GlAvatarsInline, GlAvatar, GlAvatarLink, GlBadge, GlIcon },
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
    groups: {
      type: Array,
      required: false,
      default: () => [],
    },
    deployKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
    statusCheckUrl: {
      type: String,
      required: false,
      default: null,
    },
    hmac: {
      type: Boolean,
      required: false,
      default: false,
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
    usersAndGroups() {
      return [...this.users, ...this.groups];
    },
  },
};
</script>

<template>
  <div
    class="gl-mb-4 gl-flex gl-items-center gl-gap-7 gl-border-t-1 gl-border-default"
    :class="{ 'gl-pt-4 gl-border-t-solid': showDivider }"
  >
    <div class="gl-flex gl-w-full gl-items-center">
      <div class="gl-basis-1/4">{{ title }}</div>

      <div v-if="statusCheckUrl" class="gl-grow">{{ statusCheckUrl }}</div>

      <gl-avatars-inline
        v-if="usersAndGroups.length"
        class="!gl-w-1/4"
        :avatars="usersAndGroups"
        :collapsed="true"
        :max-visible="$options.MAX_VISIBLE_AVATARS"
        :avatar-size="$options.AVATAR_SIZE"
        badge-tooltip-prop="name"
        :badge-tooltip-max-chars="$options.AVATAR_TOOLTIP_MAX_CHARS"
        :badge-sr-only-text="avatarBadgeSrOnlyText"
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link
            :key="avatar.name"
            v-gl-tooltip
            target="_blank"
            :href="avatar.webUrl"
            :title="avatar.name"
          >
            <gl-avatar
              :src="avatar.avatarUrl"
              :label="avatar.name"
              :entity-name="avatar.name"
              :alt="avatar.name"
              :size="$options.AVATAR_SIZE"
            />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>

      <gl-badge v-if="hmac" data-testid="shared-secret" class="gl-mr-2">{{
        $options.i18n.sharedSecret
      }}</gl-badge>

      <div v-if="accessLevels.length" class="gl-flex gl-flex-1 gl-flex-wrap gl-gap-2">
        <gl-badge
          v-for="(item, index) in accessLevels"
          :key="index"
          data-testid="access-level"
          :data-qa-role="$options.accessLevelsConfig[item].accessLevelLabel"
        >
          {{ $options.accessLevelsConfig[item].accessLevelLabel }}
        </gl-badge>
      </div>

      <div
        v-if="deployKeys.length"
        class="gl-mr-2 gl-flex gl-min-w-0 gl-flex-1 gl-flex-wrap gl-gap-2"
      >
        <gl-badge v-for="deployKey in deployKeys" :key="deployKey.id" data-testid="deploy-key"
          ><gl-icon name="key" class="gl-mr-2 gl-min-w-5" />
          <span class="gl-truncate">{{ deployKey.title }}</span>
        </gl-badge>
      </div>
    </div>
  </div>
</template>
