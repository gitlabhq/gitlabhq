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
  },
};
</script>

<template>
  <button
    v-collapse-toggle.context-switcher
    type="button"
    class="context-switcher-toggle gl-bg-transparent gl-border-0 border-top border-bottom gl-border-gray-a-08 gl-box-shadow-none gl-display-flex gl-align-items-center gl-font-weight-bold gl-w-full gl-pl-3 gl-pr-5 gl-h-8"
  >
    <gl-avatar :size="32" shape="rect" :src="context.avatar" class="gl-mr-3" />
    <div class="gl-overflow-auto">
      <gl-truncate :text="context.title" />
    </div>
    <span class="gl-flex-grow-1 gl-text-right">
      <gl-icon :name="collapseIcon" />
    </span>
  </button>
</template>
