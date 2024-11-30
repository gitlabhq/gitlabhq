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
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-py-5">
    <gl-link :href="href" data-testid="item-avatar" class="gl-mr-3 !gl-no-underline">
      <gl-avatar
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :entity-name="name"
        :alt="name"
        :src="avatarUrl"
        :size="48"
      />
    </gl-link>
    <div>
      <div class="gl-mb-1">
        <gl-link :href="href" class="gl-font-bold !gl-text-default">{{ fullName }}</gl-link>
        <gl-badge v-if="isOwner" variant="info">{{ s__('Runners|Owner') }}</gl-badge>
      </div>
      <div v-if="description">{{ description }}</div>
    </div>
  </div>
</template>
