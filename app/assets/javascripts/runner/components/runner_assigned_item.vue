<script>
import { GlAvatar, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
    GlLink,
  },
  props: {
    href: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
    },
    avatarUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-py-5">
    <gl-link :href="href" data-testid="item-avatar" class="gl-text-decoration-none! gl-mr-3">
      <gl-avatar shape="rect" :entity-name="name" :alt="name" :src="avatarUrl" :size="48" />
    </gl-link>

    <gl-link :href="href" class="gl-font-lg gl-font-weight-bold gl-text-gray-900!">{{
      fullName
    }}</gl-link>
  </div>
</template>
