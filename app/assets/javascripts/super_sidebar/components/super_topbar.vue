<script>
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import UserMenu from './user_menu.vue';

export default {
  components: {
    BrandLogo,
    UserMenu,
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <header class="super-topbar gl-flex gl-items-center gl-justify-between">
    <brand-logo :logo-url="sidebarData.logo_url" class="!gl-p-0" />
    <user-menu v-if="sidebarData.is_logged_in" :data="sidebarData" />
  </header>
</template>
