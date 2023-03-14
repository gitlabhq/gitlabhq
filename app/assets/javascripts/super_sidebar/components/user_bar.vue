<script>
import { GlBadge, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import logo from '../../../../views/shared/_logo.svg';
import { toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import CreateMenu from './create_menu.vue';
import Counter from './counter.vue';
import MergeRequestMenu from './merge_request_menu.vue';
import UserMenu from './user_menu.vue';

export default {
  // "GitLab Next" is a proper noun, so don't translate "Next"
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  NEXT_LABEL: 'Next',
  logo,
  components: {
    Counter,
    CreateMenu,
    GlBadge,
    GlButton,
    MergeRequestMenu,
    UserMenu,
  },
  i18n: {
    collapseSidebar: __('Collapse sidebar'),
    createNew: __('Create new...'),
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    search: __('Search'),
    todoList: __('To-Do list'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  inject: ['rootPath'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  methods: {
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, true);
    },
  },
};
</script>

<template>
  <div class="user-bar">
    <div class="gl-display-flex gl-align-items-center gl-px-3 gl-py-2 gl-gap-2">
      <a :href="rootPath">
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
        >{{ $options.NEXT_LABEL }}</gl-badge
      >
      <div class="gl-flex-grow-1"></div>
      <gl-button
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.collapseSidebar"
        :aria-label="$options.i18n.collapseSidebar"
        icon="sidebar"
        category="tertiary"
        @click="collapseSidebar"
      />
      <create-menu :groups="sidebarData.create_new_menu_groups" />
      <gl-button
        icon="search"
        :aria-label="$options.i18n.search"
        category="tertiary"
        href="/search"
      />
      <user-menu :data="sidebarData" />
    </div>
    <div class="gl-display-flex gl-justify-content-space-between gl-px-3 gl-py-2 gl-gap-2">
      <counter
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.issues"
        class="gl-flex-basis-third"
        icon="issues"
        :count="sidebarData.assigned_open_issues_count"
        :href="sidebarData.issues_dashboard_path"
        :label="$options.i18n.issues"
      />
      <merge-request-menu
        class="gl-flex-basis-third gl-display-block!"
        :items="sidebarData.merge_request_menu"
      >
        <counter
          v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.mergeRequests"
          class="gl-w-full"
          icon="merge-request-open"
          :count="sidebarData.total_merge_requests_count"
          :label="$options.i18n.mergeRequests"
        />
      </merge-request-menu>
      <counter
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.todoList"
        class="gl-flex-basis-third"
        icon="todo-done"
        :count="sidebarData.todos_pending_count"
        href="/dashboard/todos"
        :label="$options.i18n.todoList"
        data-qa-selector="todos_shortcut_button"
      />
    </div>
  </div>
</template>
