<script>
import { GlAvatar, GlAvatarLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    triggerer: {
      type: Object,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <gl-avatar-link v-if="triggerer" :href="triggerer.webUrl">
    <gl-avatar v-gl-tooltip :title="triggerer.name" :src="triggerer.avatarUrl" :size="24" />
  </gl-avatar-link>
</template>
