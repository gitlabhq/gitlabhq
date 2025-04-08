<script>
import { GlAvatar, GlAvatarLink, GlBadge, GlLink } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
    GlBadge,
    GlLink,
  },
  props: {
    href: {
      type: String,
      required: false,
      default: null,
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
    description: {
      type: String,
      required: false,
      default: null,
    },
    isOwner: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    avatarProps() {
      return {
        shape: AVATAR_SHAPE_OPTION_RECT,
        entityName: this.name,
        alt: this.name,
        src: this.avatarUrl,
        size: 32,
      };
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <li class="!gl-flex gl-items-center gl-gap-3">
    <gl-avatar-link
      v-if="href"
      :href="href"
      :data-user-id="name"
      :data-username="name"
      class="!gl-no-underline"
    >
      <gl-avatar v-bind="avatarProps" />
    </gl-avatar-link>
    <gl-avatar v-else v-bind="avatarProps" />
    <div>
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-link :href="href" class="gl-font-bold !gl-text-default">{{ fullName }}</gl-link>
        <gl-badge v-if="isOwner" variant="info">{{ s__('Runners|Owner') }}</gl-badge>
      </div>
      <p v-if="description" class="gl-mb-0 gl-text-sm gl-text-subtle">{{ description }}</p>
    </div>
  </li>
</template>
