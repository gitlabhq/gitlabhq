<script>
import { GlAvatar, GlBadge, GlLink } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  components: {
    GlAvatar,
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
        size: 48,
      };
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-py-5">
    <gl-link v-if="href" :href="href" class="gl-mr-3 !gl-no-underline">
      <gl-avatar v-bind="avatarProps" />
    </gl-link>
    <gl-avatar v-else v-bind="avatarProps" class="gl-mr-3" />
    <div>
      <div class="gl-mb-1">
        <gl-link v-if="href" :href="href" class="gl-font-bold !gl-text-default">{{
          fullName
        }}</gl-link>
        <span v-else class="gl-font-bold !gl-text-default">{{ fullName }}</span>

        <gl-badge v-if="isOwner" variant="info">{{ s__('Runners|Owner') }}</gl-badge>
      </div>
      <div v-if="description">{{ description }}</div>
    </div>
  </div>
</template>
