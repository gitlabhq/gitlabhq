<script>
import {
  GlAvatarLink,
  GlAvatarLabeled,
  GlBadge,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { generateBadges } from 'ee_else_ce/members/utils';
import { glEmojiTag } from '~/emoji';
import { __ } from '~/locale';
import { AVATAR_SIZE } from '../../constants';

export default {
  name: 'UserAvatar',
  avatarSize: AVATAR_SIZE,
  orphanedUserLabel: __('Orphaned member'),
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  components: {
    GlAvatarLink,
    GlAvatarLabeled,
    GlBadge,
  },
  directives: {
    SafeHtml,
  },
  inject: ['canManageMembers'],
  props: {
    member: {
      type: Object,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    user() {
      return this.member.user;
    },
    badges() {
      return generateBadges({
        member: this.member,
        isCurrentUser: this.isCurrentUser,
        canManageMembers: this.canManageMembers,
      }).filter((badge) => badge.show);
    },
    statusEmoji() {
      return this.user?.status?.emoji;
    },
  },
  methods: {
    glEmojiTag,
  },
};
</script>

<template>
  <gl-avatar-link
    v-if="user"
    class="js-user-link"
    :href="user.webUrl"
    :data-user-id="user.id"
    :data-username="user.username"
  >
    <gl-avatar-labeled
      :label="user.name"
      :sub-label="`@${user.username}`"
      :src="user.avatarUrl"
      :alt="user.name"
      :size="$options.avatarSize"
      :entity-name="user.name"
      :entity-id="user.id"
    >
      <template #meta>
        <div v-if="statusEmoji" class="gl-p-1">
          <span
            v-safe-html:[$options.safeHtmlConfig]="glEmojiTag(statusEmoji)"
            class="user-status-emoji gl-mr-0"
          ></span>
        </div>
        <div v-for="badge in badges" :key="badge.text" class="gl-p-1">
          <gl-badge size="sm" :variant="badge.variant">
            {{ badge.text }}
          </gl-badge>
        </div>
      </template>
    </gl-avatar-labeled>
  </gl-avatar-link>

  <gl-avatar-labeled
    v-else
    :label="$options.orphanedUserLabel"
    :alt="$options.orphanedUserLabel"
    :size="$options.avatarSize"
    :entity-name="$options.orphanedUserLabel"
    :entity-id="member.id"
  />
</template>
