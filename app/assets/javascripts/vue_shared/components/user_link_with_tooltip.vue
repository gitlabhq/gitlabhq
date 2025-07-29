<script>
import { uniqueId } from 'lodash';
import { GlAvatarLink, GlAvatar, GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlAvatarLink,
    GlAvatar,
    GlTooltip,
  },
  props: {
    avatar: {
      type: Object,
      required: true,
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      toggleId: uniqueId('user-link-'),
    };
  },
};
</script>
<template>
  <div class="gl-leading-0">
    <gl-avatar-link :id="toggleId" :href="avatar.webUrl" :aria-label="avatar.name">
      <gl-avatar :alt="avatar.name" :src="avatar.avatarUrl" :size="16" @click.stop />
    </gl-avatar-link>
    <gl-tooltip placement="top" :target="toggleId">
      <span v-if="label" class="gl-block gl-font-bold" data-testid="user-link-tooltip-label">{{
        label
      }}</span>
      <span class="gl-font-semibold" data-testid="user-link-tooltip-name">{{ avatar.name }}</span>
      <span
        v-if="avatar.username"
        class="gl-text-neutral-200"
        data-testid="user-link-tooltip-username"
        >@{{ avatar.username }}</span
      >
    </gl-tooltip>
  </div>
</template>
