<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { hasTouchCapability } from '~/lib/utils/touch_detection';
import { JS_TOGGLE_EXPAND_CLASS, JS_TOGGLE_COLLAPSE_CLASS, sidebarState } from '../constants';
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
    type: {
      type: String,
      required: false,
      default: 'expand',
    },
    icon: {
      type: String,
      required: false,
      default: 'sidebar',
    },
    ariaLabel: {
      type: String,
      required: false,
      default: null,
    },
  },
  i18n: {
    primaryNavigationSidebar: __('Primary navigation sidebar'),
  },
  tooltipCollapse: {
    placement: 'bottom',
    container: 'super-sidebar',
    title: __('Hide sidebar'),
  },
  tooltipExpand: {
    placement: 'right',
    title: __('Keep sidebar visible'),
  },
  data() {
    return sidebarState;
  },
  computed: {
    isTypeCollapse() {
      return this.type === 'collapse';
    },
    isTypeExpand() {
      return this.type === 'expand';
    },
    tooltip() {
      if (hasTouchCapability() || this.ariaLabel) {
        return null;
      }

      return this.isTypeExpand ? this.$options.tooltipExpand : this.$options.tooltipCollapse;
    },
    computedAriaLabel() {
      return this.ariaLabel || this.$options.i18n.primaryNavigationSidebar;
    },
    ariaExpanded() {
      return String(this.isTypeCollapse);
    },
  },
  mounted() {
    this.$root.$on('bv::tooltip::show', this.onTooltipShow);
  },
  beforeUnmount() {
    this.$root.$off('bv::tooltip::show', this.onTooltipShow);
  },

  methods: {
    toggle() {
      this.track(this.isTypeExpand ? 'nav_show' : 'nav_hide', {
        label: 'nav_toggle',
        property: 'nav_sidebar',
      });
      toggleSuperSidebarCollapsed(!this.isTypeExpand, true);
      this.focusOtherToggle();
    },
    focusOtherToggle() {
      this.$nextTick(() => {
        if (!this.isTypeExpand) {
          document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`).focus();
        } else {
          document.querySelector(`.${JS_TOGGLE_COLLAPSE_CLASS}`)?.focus();
        }
      });
    },
    onTooltipShow(bvEvent) {
      if (
        bvEvent.target !== this.$el ||
        (this.isTypeCollapse && !this.isCollapsed) ||
        (this.isTypeExpand && this.isCollapsed) ||
        this.isPeek ||
        this.isHoverPeek
      )
        return;

      bvEvent.preventDefault();
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip="tooltip"
    aria-controls="super-sidebar"
    :aria-expanded="ariaExpanded"
    :aria-label="computedAriaLabel"
    :icon="icon"
    data-testid="super-sidebar-toggle-button"
    category="tertiary"
    @click="toggle"
  />
</template>
