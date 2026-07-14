<script>
import { GlNavItem, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'IconOnlyToggle',
  components: { GlNavItem },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isIconOnly'],
  emits: ['toggle'],
  computed: {
    icon() {
      return this.isIconOnly ? 'collapse-right' : 'collapse-left';
    },
    text() {
      return this.isIconOnly
        ? s__('Navigation|Expand sidebar')
        : s__('Navigation|Collapse sidebar');
    },
  },
  methods: {
    emitToggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <gl-nav-item
    v-gl-tooltip.right="isIconOnly ? text : ''"
    :is-icon-only="isIconOnly"
    :icon="icon"
    :aria-label="text"
    data-testid="super-sidebar-collapse-button"
    @click="emitToggle"
  >
    {{ text }}
  </gl-nav-item>
</template>
