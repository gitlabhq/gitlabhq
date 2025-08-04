<script>
import { GlBadge, GlButton, GlModalDirective, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  destroyUserCountsManager,
  createUserCountsManager,
  userCounts,
} from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import { JS_TOGGLE_COLLAPSE_CLASS } from '../constants';
import CreateMenu from './create_menu.vue';
import Counter from './counter.vue';
import MergeRequestMenu from './merge_request_menu.vue';
import UserMenu from './user_menu.vue';
import SuperSidebarToggle from './super_sidebar_toggle.vue';
import { SEARCH_MODAL_ID } from './global_search/constants';

const trackingMixin = InternalEvents.mixin();

export default {
  // "GitLab Next" is a proper noun, so don't translate "Next"
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  NEXT_LABEL: 'Next',
  JS_TOGGLE_COLLAPSE_CLASS,
  SEARCH_MODAL_ID,
  components: {
    Counter,
    CreateMenu,
    GlBadge,
    GlButton,
    MergeRequestMenu,
    UserMenu,
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
    issues: __('Assigned issues'),
    mergeRequests: __('Merge requests'),
    todoList: __('To-Do List'),
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
      mrMenuShown: false,
      userCounts,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    mergeRequestMenuComponent() {
      return this.sidebarData.merge_request_menu ? 'merge-request-menu' : 'div';
    },
    shouldShowOrganizationSwitcher() {
      return (
        this.glFeatures.uiForOrganizations && this.isLoggedIn && window.gon.current_organization
      );
    },
  },
  created() {
    Object.assign(userCounts, this.sidebarData.user_counts);
    createUserCountsManager();

    if (
      userCounts.assigned_merge_requests === null ||
      userCounts.review_requested_merge_requests === null
    ) {
      fetchUserCounts();
    }
  },
  beforeDestroy() {
    destroyUserCountsManager();
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

    <div class="gl-mx-1 gl-flex gl-justify-between gl-gap-2">
      <div v-if="sidebarData.is_logged_in" class="gl-flex gl-w-full gl-justify-between gl-gap-2">
        <counter
          v-gl-tooltip:super-sidebar.bottom="$options.i18n.issues"
          class="dashboard-shortcuts-issues gl-basis-1/3 gl-rounded-lg"
          icon="issues"
          :count="userCounts.assigned_issues"
          :href="sidebarData.issues_dashboard_path"
          :label="$options.i18n.issues"
          data-testid="issues-shortcut-button"
          data-track-action="click_link"
          data-track-label="issues_link"
          data-track-property="nav_core_menu"
        />
        <component
          :is="mergeRequestMenuComponent"
          class="!gl-block gl-basis-1/3"
          :items="sidebarData.merge_request_menu"
          @shown="mrMenuShown = true"
          @hidden="mrMenuShown = false"
        >
          <counter
            v-gl-tooltip:super-sidebar.bottom="mrMenuShown ? '' : $options.i18n.mergeRequests"
            class="gl-w-full !gl-rounded-lg"
            :class="{
              'js-merge-request-dashboard-shortcut': !sidebarData.merge_request_menu,
            }"
            icon="merge-request"
            :href="sidebarData.merge_request_dashboard_path"
            :count="userCounts.total_merge_requests"
            :label="$options.i18n.mergeRequests"
            data-testid="merge-requests-shortcut-button"
            data-track-action="click_dropdown"
            data-track-label="merge_requests_menu"
            data-track-property="nav_core_menu"
          />
        </component>
        <counter
          v-gl-tooltip:super-sidebar.bottom="$options.i18n.todoList"
          class="shortcuts-todos js-todos-count gl-basis-1/3 gl-rounded-lg"
          icon="todo-done"
          :count="userCounts.todos"
          :href="sidebarData.todos_dashboard_path"
          :label="$options.i18n.todoList"
          data-testid="todos-shortcut-button"
          data-track-action="click_link"
          data-track-label="todos_link"
          data-track-property="nav_core_menu"
        />
      </div>
    </div>

    <div class="gl-grow gl-pb-3">
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
    </div>
    <hr aria-hidden="true" class="-gl-my-2" />
  </div>
</template>
