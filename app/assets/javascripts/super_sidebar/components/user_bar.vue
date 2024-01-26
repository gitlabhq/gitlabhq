<script>
import { GlBadge, GlButton, GlModalDirective, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  destroyUserCountsManager,
  createUserCountsManager,
  userCounts,
} from '~/super_sidebar/user_counts_manager';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import { JS_TOGGLE_COLLAPSE_CLASS } from '../constants';
import CreateMenu from './create_menu.vue';
import Counter from './counter.vue';
import MergeRequestMenu from './merge_request_menu.vue';
import UserMenu from './user_menu.vue';
import SuperSidebarToggle from './super_sidebar_toggle.vue';
import { SEARCH_MODAL_ID } from './global_search/constants';

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
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    searchKbdHelp: sprintf(
      s__('GlobalSearch|Type %{kbdOpen}/%{kbdClose} to search'),
      { kbdOpen: '<kbd>', kbdClose: '</kbd>' },
      false,
    ),
    todoList: __('To-Do list'),
    stopImpersonating: __('Stop impersonating'),
    searchBtnText: __('Search or go to…'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
      searchTooltip: this.$options.i18n.searchKbdHelp,
      userCounts,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    mergeRequestTotalCount() {
      return userCounts.assigned_merge_requests + userCounts.review_requested_merge_requests;
    },
  },
  created() {
    Object.assign(userCounts, this.sidebarData.user_counts);
    createUserCountsManager();
  },
  mounted() {
    document.addEventListener('todo:toggle', this.updateTodos);
  },
  beforeDestroy() {
    document.removeEventListener('todo:toggle', this.updateTodos);
    destroyUserCountsManager();
  },
  methods: {
    updateTodos(e) {
      userCounts.todos = e.detail.count || 0;
    },
    hideSearchTooltip() {
      this.searchTooltip = '';
    },
    showSearchTooltip() {
      this.searchTooltip = this.$options.i18n.searchKbdHelp;
    },
  },
};
</script>

<template>
  <div
    class="user-bar gl-display-flex gl-p-3 gl-gap-1"
    :class="{ 'gl-flex-direction-column gl-gap-3': sidebarData.is_logged_in }"
  >
    <div
      v-if="hasCollapseButton || sidebarData.is_logged_in"
      class="gl-display-flex gl-align-items-center gl-gap-1"
    >
      <template v-if="sidebarData.is_logged_in">
        <brand-logo :logo-url="sidebarData.logo_url" />
        <gl-badge
          v-if="sidebarData.gitlab_com_and_canary"
          variant="success"
          data-testid="canary-badge-link"
          :href="sidebarData.canary_toggle_com_url"
          size="sm"
        >
          {{ $options.NEXT_LABEL }}
        </gl-badge>
        <div class="gl-flex-grow-1"></div>
      </template>

      <super-sidebar-toggle
        v-if="hasCollapseButton"
        :class="$options.JS_TOGGLE_COLLAPSE_CLASS"
        data-testid="super-sidebar-collapse-button"
        type="collapse"
      />
      <create-menu
        v-if="sidebarData.is_logged_in && sidebarData.create_new_menu_groups.length > 0"
        :groups="sidebarData.create_new_menu_groups"
      />

      <user-menu v-if="sidebarData.is_logged_in" :data="sidebarData" />

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
    </div>
    <organization-switcher v-if="glFeatures.uiForOrganizations && isLoggedIn" />
    <div
      v-if="sidebarData.is_logged_in"
      class="gl-display-flex gl-justify-content-space-between gl-gap-2"
    >
      <counter
        v-gl-tooltip:super-sidebar.bottom="$options.i18n.issues"
        class="gl-flex-basis-third dashboard-shortcuts-issues"
        icon="issues"
        :count="userCounts.assigned_issues"
        :href="sidebarData.issues_dashboard_path"
        :label="$options.i18n.issues"
        data-testid="issues-shortcut-button"
        data-track-action="click_link"
        data-track-label="issues_link"
        data-track-property="nav_core_menu"
      />
      <merge-request-menu
        class="gl-flex-basis-third gl-display-block!"
        :items="sidebarData.merge_request_menu"
        @shown="mrMenuShown = true"
        @hidden="mrMenuShown = false"
      >
        <counter
          v-gl-tooltip:super-sidebar.bottom="mrMenuShown ? '' : $options.i18n.mergeRequests"
          class="gl-w-full"
          icon="merge-request-open"
          :count="mergeRequestTotalCount"
          :label="$options.i18n.mergeRequests"
          data-testid="merge-requests-shortcut-button"
          data-track-action="click_dropdown"
          data-track-label="merge_requests_menu"
          data-track-property="nav_core_menu"
        />
      </merge-request-menu>
      <counter
        v-gl-tooltip:super-sidebar.bottom="$options.i18n.todoList"
        class="gl-flex-basis-third shortcuts-todos js-todos-count"
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
    <button
      id="super-sidebar-search"
      v-gl-tooltip.bottom.html="searchTooltip"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      class="user-bar-button gl-display-block gl-py-3 gl-bg-gray-10 gl-rounded-base gl-text-gray-900 gl-border-none gl-line-height-1 gl-w-full"
      data-testid="super-sidebar-search-button"
    >
      <gl-icon name="search" />
      {{ $options.i18n.searchBtnText }}
    </button>
    <search-modal @shown="hideSearchTooltip" @hidden="showSearchTooltip" />
  </div>
</template>
