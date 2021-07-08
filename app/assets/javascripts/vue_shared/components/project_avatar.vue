<script>
import { GlAvatar } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
  },
  props: {
    projectName: {
      type: String,
      required: true,
    },
    projectAvatarUrl: {
      type: String,
      required: false,
      default: '',
    },
    size: {
      type: Number,
      default: 32,
      required: false,
    },
    alt: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    avatarAlt() {
      return this.alt ?? this.projectName;
    },
  },
};
</script>

<template>
  <gl-avatar
    shape="rect"
    :entity-name="projectName"
    :src="projectAvatarUrl"
    :alt="avatarAlt"
    :size="size"
  />
</template>
