<script>
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
  computed: {
    userLabel() {
      if (!this.user.status) {
        return this.user.name;
      }
      return sprintf(s__('UserAvailability|%{author} (Busy)'), {
        author: this.user.name,
      });
    },
  },
};
</script>

<template>
  <gl-avatar-link>
    <gl-avatar-labeled
      :size="32"
      :label="userLabel"
      :sub-label="user.username"
      :src="user.avatarUrl || user.avatar || user.avatar_url"
      class="gl-align-items-center"
    />
  </gl-avatar-link>
</template>
