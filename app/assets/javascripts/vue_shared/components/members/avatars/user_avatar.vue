<script>
import { GlAvatarLink, GlAvatarLabeled, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { __ } from '~/locale';
import { AVATAR_SIZE } from '../constants';

export default {
  name: 'UserAvatar',
  avatarSize: AVATAR_SIZE,
  orphanedUserLabel: __('Orphaned member'),
  components: { GlAvatarLink, GlAvatarLabeled },
  directives: {
    SafeHtml,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    user() {
      return this.member.user;
    },
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
    />
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
