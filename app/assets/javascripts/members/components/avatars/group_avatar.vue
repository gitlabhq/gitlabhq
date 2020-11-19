<script>
import { GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';
import { AVATAR_SIZE } from '../../constants';

export default {
  name: 'GroupAvatar',
  avatarSize: AVATAR_SIZE,
  components: { GlAvatarLink, GlAvatarLabeled },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    group() {
      return this.member.sharedWithGroup;
    },
  },
};
</script>

<template>
  <gl-avatar-link :href="group.webUrl">
    <gl-avatar-labeled
      :label="group.fullName"
      :src="group.avatarUrl"
      :alt="group.fullName"
      :size="$options.avatarSize"
      :entity-name="group.name"
      :entity-id="group.id"
    />
  </gl-avatar-link>
</template>
