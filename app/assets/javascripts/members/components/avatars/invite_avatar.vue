<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import { AVATAR_SIZE } from '../../constants';

export default {
  name: 'InviteAvatar',
  avatarSize: AVATAR_SIZE,
  components: { GlAvatarLabeled },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    invite() {
      return this.member.invite;
    },
  },
};
</script>

<template>
  <gl-avatar-labeled
    :label="invite.email"
    :src="invite.avatarUrl"
    :alt="invite.email"
    :size="$options.avatarSize"
    :entity-name="invite.email"
    :entity-id="member.id"
  />
</template>
