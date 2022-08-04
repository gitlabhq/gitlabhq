<script>
import { GlAvatar } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  components: {
    GlAvatar,
  },
  props: {
    projectId: {
      type: Number,
      default: 0,
      required: false,
    },
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
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-avatar
    :shape="$options.AVATAR_SHAPE_OPTION_RECT"
    :entity-id="projectId"
    :entity-name="projectName"
    :src="projectAvatarUrl"
    :alt="avatarAlt"
    :size="size"
  />
</template>
