<script>
import { GlDrawer } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import { s__ } from '~/locale';

export default {
  name: 'SmallScreenDrawerNavigation',
  components: {
    GlDrawer,
    DomElementListener,
  },
  i18n: {
    smallScreenFiltersDrawerHeader: s__('GlobalSearch|Filters'),
  },
  data() {
    return {
      openSmallScreenFilters: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      if (!this.openSmallScreenFilters) return '0';
      return getContentWrapperHeight();
    },
  },
  methods: {
    closeSmallScreenFilters() {
      this.openSmallScreenFilters = false;
    },
    toggleSmallScreenFilters() {
      this.openSmallScreenFilters = !this.openSmallScreenFilters;
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <dom-element-listener selector="#js-open-mobile-filters" @click="toggleSmallScreenFilters">
    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      variant="sidebar"
      class="small-screen-drawer-navigation"
      :open="openSmallScreenFilters"
      @close="closeSmallScreenFilters"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">
          {{ $options.i18n.smallScreenFiltersDrawerHeader }}
        </h2>
      </template>
      <template #default>
        <div>
          <slot></slot>
        </div>
      </template>
    </gl-drawer>
  </dom-element-listener>
</template>
