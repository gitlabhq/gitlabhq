<script>
import { GlTruncate, GlAvatar, GlCollapseToggleDirective, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlTruncate,
    GlAvatar,
    GlIcon,
  },
  directives: {
    CollapseToggle: GlCollapseToggleDirective,
  },
  props: {
    /*
     * Contains metadata about the current view, e.g. `id`, `title` and `avatar`
     */
    context: {
      type: Object,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    avatarShape() {
      return this.context.avatar_shape || 'rect';
    },
  },
};
</script>

<template>
  <button
    v-collapse-toggle.context-switcher
    type="button"
    class="context-switcher-toggle gl-p-0 gl-bg-transparent gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-border-0 border-top border-bottom gl-border-gray-a-08 gl-box-shadow-none gl-display-flex gl-align-items-center gl-font-weight-bold gl-w-full gl-h-8 gl-flex-shrink-0"
  >
    <span
      v-if="context.icon"
      class="gl-avatar avatar-container gl-bg-t-gray-a-08 icon-avatar rect-avatar s24 gl-mr-3 gl-ml-4"
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
      class="gl-mr-3 gl-ml-4"
    />
    <div class="gl-overflow-auto gl-text-gray-900">
      <gl-truncate :text="context.title" />
    </div>
    <span class="gl-flex-grow-1 gl-text-right gl-mr-4">
      <gl-icon class="gl-text-gray-400" :name="collapseIcon" />
    </span>
  </button>
</template>
