<script>
import { GlAvatar } from '@gitlab/ui';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  components: {
    GlAvatar,
  },
  props: {
    projectId: {
      type: [Number, String],
      default: 0,
      required: false,
      validator(value) {
        return typeof value === 'string' ? isGid(value) : true;
      },
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
    entityId() {
      return isGid(this.projectId) ? getIdFromGraphQLId(this.projectId) : this.projectId;
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-avatar
    :shape="$options.AVATAR_SHAPE_OPTION_RECT"
    :entity-id="entityId"
    :entity-name="projectName"
    :src="projectAvatarUrl"
    :alt="avatarAlt"
    :size="size"
    :fallback-on-error="true"
    itemprop="image"
  />
</template>
