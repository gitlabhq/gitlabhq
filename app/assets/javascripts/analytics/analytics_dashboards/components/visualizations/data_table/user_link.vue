<script>
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';

export default {
  name: 'UserLink',
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  avatarSize: 32,
};
</script>
<template>
  <gl-avatar-link target="blank" :href="webUrl">
    <gl-avatar-labeled
      :label="name"
      :sub-label="`@${username}`"
      :src="avatarUrl"
      :alt="`${username} avatar`"
      :size="$options.avatarSize"
      fallback-on-error
    />
  </gl-avatar-link>
</template>
