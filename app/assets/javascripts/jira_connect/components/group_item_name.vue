<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';

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
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-icon name="folder-o" class="gl-mr-3" />
    <div class="gl-display-none gl-flex-shrink-0 gl-sm-display-flex gl-mr-3">
      <gl-avatar :size="32" shape="rect" :entity-name="group.name" :src="group.avatar_url" />
    </div>

    <div>
      <span class="gl-mr-3 gl-text-gray-900! gl-font-weight-bold">
        {{ group.full_name }}
      </span>
      <div v-if="group.description">
        <p class="gl-mt-2! gl-mb-0 gl-text-gray-600" v-text="group.description"></p>
      </div>
    </div>
  </div>
</template>
