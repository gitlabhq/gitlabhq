<script>
import NavItem from './nav_item.vue';

export default {
  name: 'SidebarMenu',
  components: {
    NavItem,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <nav class="gl-py-2 gl-relative">
    <ul class="gl-px-2 gl-list-style-none">
      <nav-item v-for="item in items" :key="`menu-${item.title}`" :item="item" />
    </ul>
  </nav>
</template>
