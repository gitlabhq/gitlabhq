<script>
import { GlBadge } from '@gitlab/ui';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import CreateMenu from './create_menu.vue';
import UserMenu from './user_menu.vue';
import UserCounts from './user_counts.vue';

export default {
  // "GitLab Next" is a proper noun, so don't translate "Next"
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  NEXT_LABEL: 'Next',
  components: {
    GlBadge,
    BrandLogo,
    CreateMenu,
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
    <div class="gl-flex gl-items-center gl-gap-2">
      <brand-logo :logo-url="sidebarData.logo_url" class="!gl-p-0" />

      <gl-badge
        v-if="sidebarData.gitlab_com_and_canary"
        variant="success"
        data-testid="canary-badge-link"
        :href="sidebarData.canary_toggle_com_url"
      >
        {{ $options.NEXT_LABEL }}
      </gl-badge>
    </div>

    <div class="gl-flex gl-gap-2">
      <create-menu
        v-if="sidebarData.is_logged_in && sidebarData.create_new_menu_groups.length > 0"
        :groups="sidebarData.create_new_menu_groups"
      />

      <user-counts
        v-if="sidebarData.is_logged_in"
        :sidebar-data="sidebarData"
        counter-class="gl-button btn btn-default btn-default-tertiary"
      />
      <user-menu v-if="sidebarData.is_logged_in" :data="sidebarData" />
    </div>
  </header>
</template>
