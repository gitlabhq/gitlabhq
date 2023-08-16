<script>
import { GlIcon } from '@gitlab/ui';
import ContextHeader from './context_header.vue';

export default {
  components: {
    GlIcon,
    ContextHeader,
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
  },
};
</script>

<template>
  <context-header
    :context="context"
    tag="button"
    type="button"
    class="context-switcher-toggle gl-p-0 gl-bg-transparent gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-border-0 gl-box-shadow-none gl-text-left"
    data-testid="context-switcher"
  >
    <template #end>
      <gl-icon class="gl-text-gray-400" :name="collapseIcon" />
    </template>
  </context-header>
</template>
