<script>
import { FREQUENT_ITEMS_PROJECTS, FREQUENT_ITEMS_GROUPS } from '~/frequent_items/constants';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import TopNavContainerView from './top_nav_container_view.vue';
import TopNavMenuItem from './top_nav_menu_item.vue';

const ACTIVE_CLASS = 'gl-shadow-none! gl-font-weight-bold! active';
const SECONDARY_GROUP_CLASS = 'gl-pt-3 gl-mt-3 gl-border-1 gl-border-t-solid gl-border-gray-100';

export default {
  components: {
    KeepAliveSlots,
    TopNavContainerView,
    TopNavMenuItem,
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
    return {
      activeId: '',
    };
  },
  computed: {
    menuItemGroups() {
      return [
        { key: 'primary', items: this.primary, classes: '' },
        {
          key: 'secondary',
          items: this.secondary,
          classes: SECONDARY_GROUP_CLASS,
        },
      ].filter((x) => x.items?.length);
    },
    allMenuItems() {
      return this.menuItemGroups.flatMap((x) => x.items);
    },
    activeMenuItem() {
      return this.allMenuItems.find((x) => x.id === this.activeId);
    },
    activeView() {
      return this.activeMenuItem?.view;
    },
    menuClass() {
      if (!this.activeView) {
        return 'gl-w-full';
      }

      return '';
    },
  },
  created() {
    // Initialize activeId based on initialization prop
    this.activeId = this.allMenuItems.find((x) => x.active)?.id;
  },
  methods: {
    onClick({ id, href }) {
      // If we're a link, let's just do the default behavior so the view won't change
      if (href) {
        return;
      }

      this.activeId = id;
    },
    menuItemClasses(menuItem) {
      if (menuItem.id === this.activeId) {
        return ACTIVE_CLASS;
      }

      return '';
    },
  },
  FREQUENT_ITEMS_PROJECTS,
  FREQUENT_ITEMS_GROUPS,
  // expose for unit tests
  ACTIVE_CLASS,
  SECONDARY_GROUP_CLASS,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-stretch">
    <div
      class="gl-w-grid-size-30 gl-flex-shrink-0 gl-bg-gray-10"
      :class="menuClass"
      data-testid="menu-sidebar"
    >
      <div
        class="gl-py-3 gl-px-5 gl-h-full gl-display-flex gl-align-items-stretch gl-flex-direction-column"
      >
        <div
          v-for="group in menuItemGroups"
          :key="group.key"
          :class="group.classes"
          data-testid="menu-item-group"
        >
          <top-nav-menu-item
            v-for="(menu, index) in group.items"
            :key="menu.id"
            data-testid="menu-item"
            :class="[{ 'gl-mt-1': index !== 0 }, menuItemClasses(menu)]"
            :menu-item="menu"
            @click="onClick(menu)"
          />
        </div>
      </div>
    </div>
    <keep-alive-slots
      v-show="activeView"
      :slot-key="activeView"
      class="gl-w-grid-size-40 gl-overflow-hidden gl-py-3 gl-px-5"
      data-testid="menu-subview"
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
