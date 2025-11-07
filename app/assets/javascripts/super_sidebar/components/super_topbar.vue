<script>
import { GlBadge, GlButton, GlIcon, GlModalDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SuperSidebarToggle from './super_sidebar_toggle.vue';
import CreateMenu from './create_menu.vue';
import UserMenu from './user_menu.vue';
import UserCounts from './user_counts.vue';
import PromoMenu from './promo_menu.vue';
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
    SuperSidebarToggle,
    CreateMenu,
    UserCounts,
    UserMenu,
    PromoMenu,
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
    skipToMainContent: __('Skip to main content'),
    adminArea: s__('Navigation|Admin'),
    searchBtnText: __('Search or go to…'),
    menuLabel: __('Open navigation menu'),
  },
  inject: ['isSaas'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isAdmin() {
      return parseBoolean(this.sidebarData?.admin_mode?.user_is_admin);
    },
    isLoggedIn() {
      return parseBoolean(this.sidebarData.is_logged_in);
    },
    allowSignUp() {
      return parseBoolean(this.sidebarData?.allow_signup);
    },
    signInVisible() {
      return parseBoolean(this.sidebarData?.sign_in_visible);
    },
    shouldShowOrganizationSwitcher() {
      return (
        this.glFeatures.uiForOrganizations &&
        this.isLoggedIn &&
        window.gon.current_organization &&
        this.sidebarData.has_multiple_organizations
      );
    },
    showAdminButton() {
      return (
        this.isAdmin &&
        (!this.sidebarData.admin_mode.admin_mode_feature_enabled ||
          this.sidebarData.admin_mode.admin_mode_active)
      );
    },
  },
};
</script>

<template>
  <header
    class="super-topbar js-super-topbar gl-grid gl-grid-cols-[1fr_auto_1fr] gl-items-center gl-outline-none"
    tabindex="1"
    autofocus
  >
    <gl-button
      class="gl-t-0 gl-sr-only !gl-fixed gl-left-0 gl-z-9999 !gl-m-3 !gl-px-4 focus:gl-not-sr-only"
      data-testid="super-topbar-skip-to"
      href="#content-body"
      variant="confirm"
    >
      {{ $options.i18n.skipToMainContent }}
    </gl-button>
    <div class="gl-flex gl-items-center gl-gap-3">
      <brand-logo :logo-url="sidebarData.logo_url" class="!gl-p-0" />

      <gl-badge
        v-if="sidebarData.gitlab_com_and_canary"
        variant="success"
        data-testid="canary-badge-link"
        :href="sidebarData.canary_toggle_com_url"
      >
        {{ $options.NEXT_LABEL }}
      </gl-badge>

      <super-sidebar-toggle
        v-if="sidebarData.current_menu_items.length"
        icon="hamburger"
        type="expand"
        class="xl:gl-hidden"
        :aria-label="$options.i18n.menuLabel"
      />

      <promo-menu
        v-if="!isLoggedIn"
        :pricing-url="sidebarData.compare_plans_url"
        class="gl-hidden lg:gl-flex"
      />

      <organization-switcher v-if="shouldShowOrganizationSwitcher" class="gl-hidden md:gl-block" />
    </div>

    <gl-button
      id="super-sidebar-search"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      button-text-classes="gl-flex gl-items-center"
      category="tertiary"
      class="topbar-search-button gl-max-w-88 !gl-rounded-[.75rem] !gl-bg-default !gl-pl-3 !gl-pr-2 hover:!gl-border-alpha-dark-40 dark:!gl-bg-alpha-light-8 dark:hover:!gl-border-alpha-light-36"
      data-testid="super-topbar-search-button"
    >
      <gl-icon name="search" class="gl-shrink-0" />
      <span class="topbar-search-button-placeholder gl-min-w-[24vw] gl-text-left">{{
        $options.i18n.searchBtnText
      }}</span>
      <kbd class="gl-mr-1 gl-hidden gl-shrink-0 gl-shadow-none md:gl-block">/</kbd>
    </gl-button>

    <div class="gl-flex gl-justify-end gl-gap-3">
      <template v-if="isLoggedIn">
        <create-menu
          v-if="isLoggedIn && sidebarData.create_new_menu_groups.length > 0"
          :groups="sidebarData.create_new_menu_groups"
        />
        <div
          class="gl-border-r gl-mx-2 gl-my-3 gl-hidden gl-h-5 gl-w-1 gl-border-r-strong lg:gl-block"
        ></div>

        <user-counts
          v-if="isLoggedIn"
          :sidebar-data="sidebarData"
          class="gl-hidden md:gl-flex"
          counter-class="gl-button btn btn-default btn-default-tertiary !gl-px-3"
        />

        <gl-button
          v-if="showAdminButton"
          :href="sidebarData.admin_url"
          icon="admin"
          class="topbar-admin-link gl-hidden !gl-rounded-lg sm:gl-mr-1 xl:gl-flex"
          data-testid="topbar-admin-link"
        >
          {{ $options.i18n.adminArea }}
        </gl-button>

        <user-menu :data="sidebarData" />
      </template>
      <template v-else>
        <gl-button
          v-if="allowSignUp"
          :href="sidebarData.new_user_registration_path"
          variant="confirm"
          class="topbar-signup-button gl-hidden lg:gl-flex"
          data-testid="topbar-signup-button"
        >
          {{ isSaas ? __('Get free trial') : __('Register') }}
        </gl-button>
        <gl-button
          v-if="signInVisible"
          :href="sidebarData.sign_in_path"
          class="gl-hidden lg:gl-flex"
          data-testid="topbar-signin-button"
        >
          {{ __('Sign in') }}
        </gl-button>
        <promo-menu
          v-if="!isLoggedIn"
          :sidebar-data="sidebarData"
          :pricing-url="sidebarData.compare_plans_url"
          class="gl-flex lg:gl-hidden"
        />
      </template>
    </div>

    <search-modal />
  </header>
</template>
