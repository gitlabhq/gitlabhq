<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  width: {
    expanded: '482px',
    collapsed: '58px',
  },
  i18n: {
    toggleTxt: __('Collapse'),
  },
  components: {
    GlButton,
    GlIcon,
  },
  data() {
    return {
      isExpanded: false,
      topPosition: 0,
    };
  },
  computed: {
    buttonIconName() {
      return this.isExpanded ? 'chevron-double-lg-right' : 'chevron-double-lg-left';
    },
    buttonClass() {
      return this.isExpanded ? 'gl-justify-content-end!' : '';
    },
    rootStyle() {
      const { expanded, collapsed } = this.$options.width;
      const top = this.topPosition;
      const style = { top: `${top}px` };

      return this.isExpanded ? { ...style, width: expanded } : { ...style, width: collapsed };
    },
  },
  mounted() {
    this.setTopPosition();
  },
  methods: {
    setTopPosition() {
      const navbarEl = document.querySelector('.js-navbar');

      if (navbarEl) {
        this.topPosition = navbarEl.getBoundingClientRect().bottom;
      }
    },
    toggleDrawer() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>
<template>
  <aside
    aria-live="polite"
    class="gl-fixed gl-right-0 gl-h-full gl-bg-gray-10 gl-transition-medium gl-border-l-solid gl-border-1 gl-border-gray-100"
    :style="rootStyle"
  >
    <gl-button
      category="tertiary"
      class="gl-w-full gl-h-9 gl-rounded-0! gl-border-none! gl-border-b-solid! gl-border-1! gl-border-gray-100 gl-text-decoration-none! gl-outline-0! gl-display-flex"
      :class="buttonClass"
      :title="__('Toggle sidebar')"
      data-testid="toggleBtn"
      @click="toggleDrawer"
    >
      <span v-if="isExpanded" class="gl-text-gray-500 gl-mr-3" data-testid="collapse-text">{{
        __('Collapse')
      }}</span>
      <gl-icon data-testid="toggle-icon" :name="buttonIconName" />
    </gl-button>
    <div v-if="isExpanded" class="gl-p-5" data-testid="drawer-content"></div>
  </aside>
</template>
