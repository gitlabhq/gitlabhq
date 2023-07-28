<script>
import { GlTruncate, GlAvatar, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlTruncate,
    GlAvatar,
    GlIcon,
  },
  props: {
    /*
     * Contains metadata about the current view, e.g. `id`, `title` and `avatar`
     */
    context: {
      type: Object,
      required: true,
    },
    tag: {
      type: String,
      required: false,
      default: 'div',
    },
  },
  computed: {
    avatarShape() {
      return this.context.avatar_shape || 'rect';
    },
  },
};
</script>

<template>
  <component
    :is="tag"
    class="border-top border-bottom gl-border-gray-a-08! gl-display-flex gl-align-items-center gl-gap-3 gl-font-weight-bold gl-w-full gl-h-8 gl-px-4 gl-flex-shrink-0"
  >
    <span
      v-if="context.icon"
      class="gl-avatar avatar-container gl-bg-t-gray-a-08 icon-avatar rect-avatar s24"
    >
      <gl-icon class="gl-text-gray-700" :name="context.icon" :size="16" />
    </span>
    <gl-avatar
      v-else
      :size="24"
      :shape="avatarShape"
      :entity-name="context.title"
      :entity-id="context.id"
      :src="context.avatar"
    />
    <div class="gl-flex-grow-1 gl-overflow-auto gl-text-gray-900">
      <gl-truncate :text="context.title" />
    </div>
    <slot name="end"></slot>
  </component>
</template>
