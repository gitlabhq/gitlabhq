<script>
import { GlBadge, GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { highCountTrim } from '~/lib/utils/text_utility';
import logo from '../../../../views/shared/_logo.svg';
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
  logo,
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
  },
  i18n: {
    createNew: __('Create new...'),
    homepage: __('Homepage'),
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    search: __('Search'),
    searchKbdHelp: sprintf(
      s__('GlobalSearch|Search GitLab %{kbdOpen}/%{kbdClose}'),
      { kbdOpen: '<kbd>', kbdClose: '</kbd>' },
      false,
    ),
    todoList: __('To-Do list'),
    stopImpersonating: __('Stop impersonating'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
    SafeHtml,
  },
  inject: ['rootPath', 'isImpersonating'],
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
      todoCount: this.sidebarData.todos_pending_count,
      searchTooltip: this.$options.i18n.searchKbdHelp,
    };
  },
  computed: {
    formattedTodoCount() {
      return highCountTrim(this.todoCount);
    },
  },
  mounted() {
    document.addEventListener('todo:toggle', this.updateTodos);
  },
  beforeDestroy() {
    document.removeEventListener('todo:toggle', this.updateTodos);
  },
  methods: {
    updateTodos(e) {
      this.todoCount = e.detail.count || 0;
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
  <div class="user-bar">
    <div class="gl-display-flex gl-align-items-center gl-px-3 gl-py-2">
      <a
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.homepage"
        class="tanuki-logo-container"
        :href="rootPath"
        :title="$options.i18n.homepage"
        data-track-action="click_link"
        data-track-label="gitlab_logo_link"
        data-track-property="nav_core_menu"
      >
        <img
          v-if="sidebarData.logo_url"
          data-testid="brand-header-custom-logo"
          :src="sidebarData.logo_url"
          class="gl-h-6"
        />
        <span v-else v-safe-html="$options.logo"></span>
      </a>
      <gl-badge
        v-if="sidebarData.gitlab_com_and_canary"
        variant="success"
        :href="sidebarData.canary_toggle_com_url"
        size="sm"
        class="gl-ml-2"
      >
        {{ $options.NEXT_LABEL }}
      </gl-badge>
      <div class="gl-flex-grow-1"></div>
      <super-sidebar-toggle
        v-if="hasCollapseButton"
        :class="$options.JS_TOGGLE_COLLAPSE_CLASS"
        tooltip-placement="bottom"
        tooltip-container="super-sidebar"
        data-testid="super-sidebar-collapse-button"
      />
      <create-menu :groups="sidebarData.create_new_menu_groups" />

      <gl-button
        id="super-sidebar-search"
        v-gl-tooltip.bottom.hover.html="searchTooltip"
        v-gl-modal="$options.SEARCH_MODAL_ID"
        data-testid="super-sidebar-search-button"
        icon="search"
        :aria-label="$options.i18n.search"
        category="tertiary"
      />
      <search-modal @shown="hideSearchTooltip" @hidden="showSearchTooltip" />

      <user-menu :data="sidebarData" />

      <gl-button
        v-if="isImpersonating"
        v-gl-tooltip
        :href="sidebarData.stop_impersonation_path"
        :title="$options.i18n.stopImpersonating"
        :aria-label="$options.i18n.stopImpersonating"
        icon="incognito"
        variant="confirm"
        category="tertiary"
        data-method="delete"
        data-testid="stop-impersonation-btn"
      />
    </div>
    <div class="gl-display-flex gl-justify-content-space-between gl-px-3 gl-py-2 gl-gap-2">
      <counter
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.issues"
        class="gl-flex-basis-third dashboard-shortcuts-issues"
        icon="issues"
        :count="sidebarData.assigned_open_issues_count"
        :href="sidebarData.issues_dashboard_path"
        :label="$options.i18n.issues"
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
          v-gl-tooltip:super-sidebar.hover.bottom="mrMenuShown ? '' : $options.i18n.mergeRequests"
          class="gl-w-full"
          icon="merge-request-open"
          :count="sidebarData.total_merge_requests_count"
          :label="$options.i18n.mergeRequests"
          data-track-action="click_dropdown"
          data-track-label="merge_requests_menu"
          data-track-property="nav_core_menu"
        />
      </merge-request-menu>
      <counter
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.todoList"
        class="gl-flex-basis-third shortcuts-todos js-todos-count"
        icon="todo-done"
        :count="formattedTodoCount"
        href="/dashboard/todos"
        :label="$options.i18n.todoList"
        data-qa-selector="todos_shortcut_button"
        data-track-action="click_link"
        data-track-label="todos_link"
        data-track-property="nav_core_menu"
      />
    </div>
  </div>
</template>
