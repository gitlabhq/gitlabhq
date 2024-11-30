<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  components: {
    GlAvatar,
    GlIcon,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <gl-icon name="folder" class="gl-mr-3" />
    <div class="gl-mr-3 gl-hidden gl-shrink-0 sm:gl-flex">
      <gl-avatar
        :size="32"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :entity-name="group.name"
        :src="group.avatar_url"
      />
    </div>

    <div>
      <span class="gl-mr-3 gl-font-bold !gl-text-default">
        {{ group.full_name }}
      </span>
      <div v-if="group.description">
        <p class="!gl-mt-2 gl-mb-0 gl-text-subtle" v-text="group.description"></p>
      </div>
    </div>
  </div>
</template>
