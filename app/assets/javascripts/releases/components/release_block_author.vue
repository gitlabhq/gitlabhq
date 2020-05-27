<script>
import { __, sprintf } from '~/locale';
import { GlSprintf } from '@gitlab/ui';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  name: 'ReleaseBlockAuthor',
  components: {
    GlSprintf,
    UserAvatarLink,
  },
  props: {
    author: {
      type: Object,
      required: true,
    },
  },
  computed: {
    userImageAltDescription() {
      return this.author && this.author.username
        ? sprintf(__("%{username}'s avatar"), { username: this.author.username })
        : null;
    },
  },
};
</script>

<template>
  <div class="d-flex">
    <gl-sprintf :message="__('by %{user}')">
      <template #user>
        <user-avatar-link
          class="gl-ml-2"
          :link-href="author.webUrl"
          :img-src="author.avatarUrl"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
        />
      </template>
    </gl-sprintf>
  </div>
</template>
