<script>
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import UserMenu from './user_menu.vue';
import UserCounts from './user_counts.vue';

export default {
  components: {
    BrandLogo,
    UserCounts,
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

    <div class="gl-flex gl-gap-2">
      <user-counts
        v-if="sidebarData.is_logged_in"
        :sidebar-data="sidebarData"
        counter-class="gl-button btn btn-default btn-default-tertiary"
      />
      <user-menu v-if="sidebarData.is_logged_in" :data="sidebarData" />
    </div>
  </header>
</template>
