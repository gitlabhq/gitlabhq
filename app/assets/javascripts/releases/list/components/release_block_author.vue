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
    <gl-sprintf message="by %{user}">
      <template #user>
        <user-avatar-link
          class="prepend-left-4"
          :link-href="author.web_url"
          :img-src="author.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
        />
      </template>
    </gl-sprintf>
  </div>
</template>
