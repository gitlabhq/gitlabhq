<script>
import TopNavMenuItem from './top_nav_menu_item.vue';

const BORDER_CLASSES = 'gl-pt-3 gl-border-1 gl-border-t-solid';

export default {
  components: {
    TopNavMenuItem,
  },
  props: {
    sections: {
      type: Array,
      required: true,
    },
    withTopBorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    isPrimarySection: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onClick(menuItem) {
      // If we're a link, let's just do the default behavior so the view won't change
      if (menuItem.href) {
        return;
      }

      this.$emit('menu-item-click', menuItem);
    },
    getMenuSectionClasses(index) {
      // This is a method instead of a computed so we don't have to incur the cost of
      // creating a whole new array/object.
      const hasBorder = this.withTopBorder || index > 0;
      return {
        [BORDER_CLASSES]: hasBorder,
        'gl-border-gray-100': hasBorder && this.isPrimarySection,
        'gl-border-gray-50': hasBorder && !this.isPrimarySection,
        'gl-mt-3': index > 0,
      };
    },
  },
  // Expose for unit tests
  BORDER_CLASSES,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-stretch gl-flex-direction-column">
    <div
      v-for="({ id, menuItems }, sectionIndex) in sections"
      :key="id"
      :class="getMenuSectionClasses(sectionIndex)"
      data-testid="menu-section"
    >
      <template v-for="(menuItem, menuItemIndex) in menuItems">
        <strong
          v-if="menuItem.type == 'header'"
          :key="menuItem.title"
          class="gl-px-4 gl-py-2 gl-text-gray-900 gl-display-block"
          :class="{ 'gl-pt-3!': menuItemIndex > 0 }"
          data-testid="menu-header"
        >
          {{ menuItem.title }}
        </strong>
        <top-nav-menu-item
          v-else
          :key="menuItem.id"
          :menu-item="menuItem"
          data-testid="menu-item"
          class="gl-w-full"
          :class="{ 'gl-mt-1': menuItemIndex > 0 }"
          @click="onClick(menuItem)"
        />
      </template>
    </div>
  </div>
</template>
