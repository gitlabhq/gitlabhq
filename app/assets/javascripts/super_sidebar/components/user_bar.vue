<script>
import { GlBadge, GlButton, GlModalDirective, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import { JS_TOGGLE_COLLAPSE_CLASS } from '../constants';
import CreateMenu from './create_menu.vue';
import UserMenu from './user_menu.vue';
import SuperSidebarToggle from './super_sidebar_toggle.vue';
import UserCounts from './user_counts.vue';
import { SEARCH_MODAL_ID } from './global_search/constants';

const trackingMixin = InternalEvents.mixin();

export default {
  // "GitLab Next" is a proper noun, so don't translate "Next"
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  NEXT_LABEL: 'Next',
  JS_TOGGLE_COLLAPSE_CLASS,
  SEARCH_MODAL_ID,
  components: {
    CreateMenu,
    GlBadge,
    GlButton,
    UserMenu,
    UserCounts,
    SearchModal: () =>
      import(
        /* webpackChunkName: 'global_search_modal' */ './global_search/components/global_search.vue'
      ),
    SuperSidebarToggle,
    BrandLogo,
    GlIcon,
    OrganizationSwitcher: () =>
      import(/* webpackChunkName: 'organization_switcher' */ './organization_switcher.vue'),
  },
  i18n: {
    stopImpersonating: __('Stop impersonating'),
    searchBtnText: __('Search or go to…'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  inject: ['isImpersonating'],
  props: {
    hasCollapseButton: {
      default: true,
      type: Boolean,
      required: false,
    },
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    shouldShowOrganizationSwitcher() {
      return (
        this.glFeatures.uiForOrganizations &&
        this.isLoggedIn &&
        window.gon.current_organization &&
        this.sidebarData.has_multiple_organizations
      );
    },
  },
};
</script>

<template>
  <div
    class="user-bar gl-flex gl-gap-1 gl-p-3"
    :class="{ 'gl-flex-col gl-gap-3': sidebarData.is_logged_in }"
  >
    <div
      v-if="hasCollapseButton || sidebarData.is_logged_in"
      class="gl-flex gl-items-center gl-gap-1"
    >
      <template v-if="sidebarData.is_logged_in">
        <brand-logo :logo-url="sidebarData.logo_url" />
        <gl-badge
          v-if="sidebarData.gitlab_com_and_canary"
          variant="success"
          data-testid="canary-badge-link"
          :href="sidebarData.canary_toggle_com_url"
        >
          {{ $options.NEXT_LABEL }}
        </gl-badge>
        <div class="gl-grow"></div>
      </template>

      <super-sidebar-toggle
        v-if="hasCollapseButton"
        :class="$options.JS_TOGGLE_COLLAPSE_CLASS"
        data-testid="super-sidebar-collapse-button"
        type="collapse"
      />

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

      <create-menu
        v-if="sidebarData.is_logged_in && sidebarData.create_new_menu_groups.length > 0"
        :groups="sidebarData.create_new_menu_groups"
      />

      <user-menu v-if="isLoggedIn" :data="sidebarData" />
    </div>

    <organization-switcher v-if="shouldShowOrganizationSwitcher" />

    <gl-button
      id="super-sidebar-search"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      class="user-bar-button !gl-rounded-lg !gl-px-3 !gl-py-1"
      button-text-classes="gl-flex gl-w-full !gl-py-3"
      block
      data-testid="super-sidebar-search-button"
      @click="trackEvent('click_search_button_to_activate_command_palette')"
    >
      <gl-icon name="search" />
      <span class="gl-grow gl-text-left">{{ $options.i18n.searchBtnText }}</span>
      <gl-icon name="quick-actions" />
    </gl-button>
    <search-modal />

    <user-counts
      v-if="sidebarData.is_logged_in"
      counter-class="user-bar-button gl-grow gl-gap-2 gl-rounded-lg gl-py-3 gl-text-sm hover:gl-no-underline gl-leading-1"
      class="!gl-gap-2"
      :sidebar-data="sidebarData"
    />

    <hr aria-hidden="true" class="-gl-mb-2 gl-mt-2" />
  </div>
</template>
