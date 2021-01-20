<script>
import { GlIcon, GlAvatar } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlAvatar,
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
  <li class="gl-border-b-1 gl-border-b-solid gl-border-b-gray-200">
    <div class="gl-display-flex gl-align-items-center gl-py-3">
      <gl-icon name="folder-o" class="gl-mr-3" />
      <div class="gl-display-none gl-flex-shrink-0 gl-display-sm-flex gl-mr-3">
        <gl-avatar :size="32" shape="rect" :entity-name="group.name" :src="group.avatar_url" />
      </div>
      <div class="gl-min-w-0 gl-display-flex gl-flex-grow-1 gl-flex-shrink-1 gl-align-items-center">
        <div class="gl-min-w-0 gl-flex-grow-1 flex-shrink-1">
          <div class="gl-display-flex gl-align-items-center gl-flex-wrap">
            <span
              class="gl-mr-3 gl-text-gray-900! gl-font-weight-bold"
              data-testid="group-list-item-name"
            >
              {{ group.full_name }}
            </span>
          </div>
          <div v-if="group.description" data-testid="group-list-item-description">
            <p class="gl-mt-2! gl-mb-0 gl-text-gray-600" v-text="group.description"></p>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
