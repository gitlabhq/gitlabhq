<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { JS_TOGGLE_COLLAPSE_CLASS, JS_TOGGLE_EXPAND_CLASS, sidebarState } from '../constants';
import { toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tooltipContainer: {
      type: String,
      required: false,
      default: null,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'right',
    },
  },
  i18n: {
    collapseSidebar: __('Collapse sidebar'),
    expandSidebar: __('Expand sidebar'),
    navigationSidebar: __('Navigation sidebar'),
  },
  data() {
    return sidebarState;
  },
  computed: {
    tooltipTitle() {
      if (this.isPeek) return '';

      return this.isCollapsed
        ? this.$options.i18n.expandSidebar
        : this.$options.i18n.collapseSidebar;
    },
    tooltip() {
      return {
        placement: this.tooltipPlacement,
        container: this.tooltipContainer,
        title: this.tooltipTitle,
      };
    },
    ariaExpanded() {
      return String(!this.isCollapsed);
    },
  },
  methods: {
    toggle() {
      toggleSuperSidebarCollapsed(!this.isCollapsed, true);
      this.focusOtherToggle();
    },
    focusOtherToggle() {
      this.$nextTick(() => {
        const classSelector = this.isCollapsed ? JS_TOGGLE_EXPAND_CLASS : JS_TOGGLE_COLLAPSE_CLASS;
        const otherToggle = document.querySelector(`.${classSelector}`);
        otherToggle?.focus();
      });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover="tooltip"
    aria-controls="super-sidebar"
    :aria-expanded="ariaExpanded"
    :aria-label="$options.i18n.navigationSidebar"
    icon="sidebar"
    category="tertiary"
    :disabled="isPeek"
    @click="toggle"
  />
</template>
