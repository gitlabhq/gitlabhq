<script>
import { GlAvatarLink, GlAvatarLabeled, GlBadge } from '@gitlab/ui';
import { USER_AVATAR_SIZE } from '../constants';

export default {
  components: {
    GlAvatarLink,
    GlAvatarLabeled,
    GlBadge,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    adminUserPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    adminUserHref() {
      return this.adminUserPath.replace('id', this.user.username);
    },
  },
  USER_AVATAR_SIZE,
};
</script>

<template>
  <gl-avatar-link
    v-if="user"
    class="js-user-link"
    :href="adminUserHref"
    :data-user-id="user.id"
    :data-username="user.username"
  >
    <gl-avatar-labeled
      :size="$options.USER_AVATAR_SIZE"
      :src="user.avatarUrl"
      :label="user.name"
      :sub-label="user.email"
    >
      <template #meta>
        <div v-for="(badge, idx) in user.badges" :key="idx" class="gl-p-1">
          <gl-badge class="gl-display-flex!" size="sm" :variant="badge.variant">{{
            badge.text
          }}</gl-badge>
        </div>
      </template>
    </gl-avatar-labeled>
  </gl-avatar-link>
</template>
