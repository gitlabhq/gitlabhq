<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { JS_TOGGLE_EXPAND_CLASS, sidebarState } from '../constants';
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
      return this.isTypeExpand ? this.$options.tooltipExpand : this.$options.tooltipCollapse;
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
    :aria-label="$options.i18n.primaryNavigationSidebar"
    icon="sidebar"
    category="tertiary"
    @click="toggle"
  />
</template>
