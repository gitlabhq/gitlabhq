<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { JS_TOGGLE_COLLAPSE_CLASS, JS_TOGGLE_EXPAND_CLASS, sidebarState } from '../constants';
import { toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
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
    collapseSidebar: __('Hide sidebar'),
    expandSidebar: __('Keep sidebar visible'),
    primaryNavigationSidebar: __('Primary navigation sidebar'),
  },
  data() {
    return sidebarState;
  },
  computed: {
    canOpen() {
      return this.isCollapsed || this.isPeek || this.isHoverPeek;
    },
    tooltipTitle() {
      return this.canOpen ? this.$options.i18n.expandSidebar : this.$options.i18n.collapseSidebar;
    },
    tooltip() {
      return {
        placement: this.tooltipPlacement,
        container: this.tooltipContainer,
        title: this.tooltipTitle,
      };
    },
    ariaExpanded() {
      return String(!this.canOpen);
    },
  },
  methods: {
    toggle() {
      this.track(this.canOpen ? 'nav_show' : 'nav_hide', {
        label: 'nav_toggle',
        property: 'nav_sidebar',
      });
      toggleSuperSidebarCollapsed(!this.canOpen, true);
      this.focusOtherToggle();
    },
    focusOtherToggle() {
      this.$nextTick(() => {
        const classSelector = this.canOpen ? JS_TOGGLE_EXPAND_CLASS : JS_TOGGLE_COLLAPSE_CLASS;
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
    :aria-label="$options.i18n.primaryNavigationSidebar"
    icon="sidebar"
    category="tertiary"
    @click="toggle"
  />
</template>
