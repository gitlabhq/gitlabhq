<script>
import { GlBadge, GlButton, GlIcon, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
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
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    adminArea: s__('Navigation|Admin'),
    searchBtnText: __('Search or go to…'),
    stopImpersonating: __('Stop impersonating'),
  },
  inject: ['isImpersonating'],
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

      <organization-switcher v-if="shouldShowOrganizationSwitcher" />
    </div>

    <gl-button
      v-gl-modal="$options.SEARCH_MODAL_ID"
      button-text-classes="gl-flex"
      data-testid="super-topbar-search-button"
    >
      <gl-icon name="search" />
      <span class="gl-min-w-[20vw] gl-text-left">{{ $options.i18n.searchBtnText }}</span>
      <gl-icon name="quick-actions" />
    </gl-button>

    <div class="gl-flex gl-justify-end gl-gap-2">
      <create-menu
        v-if="isLoggedIn && sidebarData.create_new_menu_groups.length > 0"
        :groups="sidebarData.create_new_menu_groups"
      />

      <user-counts
        v-if="isLoggedIn"
        :sidebar-data="sidebarData"
        counter-class="gl-button btn btn-default btn-default-tertiary"
      />

      <gl-button
        v-if="isAdmin"
        data-testid="topbar-admin-link"
        :href="sidebarData.admin_url"
        icon="admin"
        size="small"
      >
        {{ $options.i18n.adminArea }}
      </gl-button>

      <gl-button
        v-if="isImpersonating"
        v-gl-tooltip.bottom
        :href="sidebarData.stop_impersonation_path"
        :title="$options.i18n.stopImpersonating"
        :aria-label="$options.i18n.stopImpersonating"
        icon="incognito"
        category="tertiary"
        data-method="delete"
        data-testid="stop-impersonation-btn"
      />
      <user-menu v-if="isLoggedIn" :data="sidebarData" />
    </div>

    <search-modal />
  </header>
</template>
