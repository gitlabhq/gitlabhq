<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ToggleSidebar',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    collapsed: {
      type: Boolean,
      required: true,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    tooltipLabel() {
      return this.collapsed ? __('Expand sidebar') : __('Collapse sidebar');
    },
    buttonIcon() {
      return this.collapsed ? 'chevron-double-lg-left' : 'chevron-double-lg-right';
    },
    allCssClasses() {
      return [this.cssClasses, { 'js-sidebar-collapsed': this.collapsed }];
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip:body.viewport.left
    :title="tooltipLabel"
    :class="allCssClasses"
    class="gutter-toggle btn-sidebar-action js-sidebar-vue-toggle"
    :icon="buttonIcon"
    category="tertiary"
    size="small"
    :aria-label="__('toggle collapse')"
    @click="toggle"
  />
</template>
