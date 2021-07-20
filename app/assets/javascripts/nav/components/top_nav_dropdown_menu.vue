<script>
import { cloneDeep } from 'lodash';
import { FREQUENT_ITEMS_PROJECTS, FREQUENT_ITEMS_GROUPS } from '~/frequent_items/constants';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import TopNavContainerView from './top_nav_container_view.vue';
import TopNavMenuSections from './top_nav_menu_sections.vue';

export default {
  components: {
    KeepAliveSlots,
    TopNavContainerView,
    TopNavMenuSections,
  },
  props: {
    primary: {
      type: Array,
      required: false,
      default: () => [],
    },
    secondary: {
      type: Array,
      required: false,
      default: () => [],
    },
    views: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    // It's expected that primary & secondary never change, so these are treated as "init" props.
    // We need to clone so that we can mutate the data without mutating the props
    const menuSections = [
      { id: 'primary', menuItems: cloneDeep(this.primary) },
      { id: 'secondary', menuItems: cloneDeep(this.secondary) },
    ].filter((x) => x.menuItems?.length);

    return {
      menuSections,
    };
  },
  computed: {
    allMenuItems() {
      return this.menuSections.flatMap((x) => x.menuItems);
    },
    activeView() {
      const active = this.allMenuItems.find((x) => x.active);

      return active?.view;
    },
    menuClass() {
      if (!this.activeView) {
        return 'gl-w-full';
      }

      return '';
    },
  },
  methods: {
    onMenuItemClick({ id }) {
      this.allMenuItems.forEach((menuItem) => {
        this.$set(menuItem, 'active', id === menuItem.id);
      });
    },
  },
  FREQUENT_ITEMS_PROJECTS,
  FREQUENT_ITEMS_GROUPS,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-stretch">
    <div
      class="gl-w-grid-size-30 gl-flex-shrink-0 gl-bg-gray-10 gl-p-3"
      :class="menuClass"
      data-testid="menu-sidebar"
    >
      <top-nav-menu-sections :sections="menuSections" @menu-item-click="onMenuItemClick" />
    </div>
    <keep-alive-slots
      v-show="activeView"
      :slot-key="activeView"
      class="gl-w-grid-size-40 gl-overflow-hidden gl-p-3"
      data-testid="menu-subview"
      data-qa-selector="menu_subview_container"
    >
      <template #projects>
        <top-nav-container-view
          :frequent-items-dropdown-type="$options.FREQUENT_ITEMS_PROJECTS.namespace"
          :frequent-items-vuex-module="$options.FREQUENT_ITEMS_PROJECTS.vuexModule"
          v-bind="views.projects"
        />
      </template>
      <template #groups>
        <top-nav-container-view
          :frequent-items-dropdown-type="$options.FREQUENT_ITEMS_GROUPS.namespace"
          :frequent-items-vuex-module="$options.FREQUENT_ITEMS_GROUPS.vuexModule"
          v-bind="views.groups"
        />
      </template>
    </keep-alive-slots>
  </div>
</template>
