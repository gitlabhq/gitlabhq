<script>
import {
  GlAvatarLink,
  GlAvatarLabeled,
  GlBadge,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { generateBadges } from 'ee_else_ce/members/utils';
import { __ } from '~/locale';
import { AVATAR_SIZE } from '../../constants';
import { glEmojiTag } from '~/emoji';

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
      return generateBadges(this.member, this.isCurrentUser).filter(badge => badge.show);
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
          <span v-safe-html:[$options.safeHtmlConfig]="glEmojiTag(statusEmoji)"></span>
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
