<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  name: 'ProjectAvatar',
  components: {
    GlAvatarLabeled,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    entityId() {
      return getIdFromGraphQLId(this.id);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-avatar-labeled
    :entity-id="entityId"
    :entity-name="name"
    :label="name"
    :label-link="webUrl"
    :src="avatarUrl"
    :size="24"
    :shape="$options.AVATAR_SHAPE_OPTION_RECT"
    fallback-on-error
  />
</template>
