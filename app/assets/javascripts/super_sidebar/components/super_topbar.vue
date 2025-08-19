<script>
import { GlBadge, GlButton, GlIcon, GlModalDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import CreateMenu from './create_menu.vue';
import UserMenu from './user_menu.vue';
import UserCounts from './user_counts.vue';
import { SEARCH_MODAL_ID } from './global_search/constants';

export default {
  // "GitLab Next" is a proper noun, so don't translate "Next"
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  NEXT_LABEL: 'Next',
  SEARCH_MODAL_ID,
  components: {
    GlBadge,
    GlButton,
    GlIcon,
    BrandLogo,
    CreateMenu,
    UserCounts,
    UserMenu,
    OrganizationSwitcher: () =>
      import(/* webpackChunkName: 'organization_switcher' */ './organization_switcher.vue'),
    SearchModal: () =>
      import(
        /* webpackChunkName: 'global_search_modal' */ './global_search/components/global_search.vue'
      ),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    adminArea: s__('Navigation|Admin'),
    searchBtnText: __('Search or go to…'),
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isAdmin() {
      return this.sidebarData?.admin_mode?.user_is_admin;
    },
    isLoggedIn() {
      return this.sidebarData.is_logged_in;
    },
    shouldShowOrganizationSwitcher() {
      return (
        this.glFeatures.uiForOrganizations && this.isLoggedIn && window.gon.current_organization
      );
    },
  },
};
</script>

<template>
  <header
    class="super-topbar gl-grid gl-w-full gl-grid-cols-[1fr_auto_1fr] gl-items-center gl-gap-4"
  >
    <div class="gl-flex gl-items-center gl-gap-3">
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

      <organization-switcher v-if="shouldShowOrganizationSwitcher" />
    </div>

    <gl-button
      id="super-sidebar-search"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      button-text-classes="gl-flex gl-w-full gl-items-center"
      class="topbar-search-button !gl-rounded-lg !gl-border-strong !gl-pl-3 !gl-pr-2 dark:!gl-bg-alpha-light-8"
      data-testid="super-topbar-search-button"
    >
      <gl-icon name="search" class="gl-shrink-0" />
      <span
        class="topbar-search-button-placeholder gl-min-w-[24vw] gl-grow gl-text-left gl-font-normal"
        >{{ $options.i18n.searchBtnText }}</span
      >
      <kbd class="gl-mr-1 gl-shrink-0 gl-shadow-none">/</kbd>
    </gl-button>

    <div class="gl-flex gl-justify-end gl-gap-3">
      <create-menu
        v-if="isLoggedIn && sidebarData.create_new_menu_groups.length > 0"
        :groups="sidebarData.create_new_menu_groups"
      />
      <div class="gl-border-r gl-my-3 gl-h-5 gl-w-1 gl-border-r-strong"></div>

      <user-counts
        v-if="isLoggedIn"
        :sidebar-data="sidebarData"
        counter-class="gl-button btn btn-default btn-default-tertiary !gl-px-3 !gl-rounded-lg"
      />

      <gl-button
        v-if="isAdmin"
        :href="sidebarData.admin_url"
        icon="admin"
        class="topbar-admin-link !gl-rounded-lg"
        data-testid="topbar-admin-link"
      >
        {{ $options.i18n.adminArea }}
      </gl-button>

      <user-menu v-if="isLoggedIn" :data="sidebarData" />
    </div>

    <search-modal />
  </header>
</template>
