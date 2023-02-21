<script>
import { GlAvatar, GlButton, GlDropdown, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import logo from '../../../../views/shared/_logo.svg';
import { toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import CreateMenu from './create_menu.vue';
import Counter from './counter.vue';
import MergeRequestMenu from './merge_request_menu.vue';

export default {
  logo,
  components: {
    GlAvatar,
    GlButton,
    GlDropdown,
    GlIcon,
    CreateMenu,
    NewNavToggle,
    Counter,
    MergeRequestMenu,
  },
  i18n: {
    collapseSidebar: __('Collapse sidebar'),
    createNew: __('Create new...'),
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    todoList: __('To-Do list'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  inject: ['rootPath', 'toggleNewNavEndpoint'],
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
      <div class="gl-flex-grow-1">
        <a v-safe-html="$options.logo" :href="rootPath"></a>
      </div>
      <gl-button
        v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.collapseSidebar"
        :aria-label="$options.i18n.collapseSidebar"
        icon="sidebar"
        category="tertiary"
        @click="collapseSidebar"
      />
      <create-menu :groups="sidebarData.create_new_menu_groups" />
      <button class="gl-border-none">
        <gl-icon name="search" class="gl-vertical-align-middle" />
      </button>
      <gl-dropdown data-testid="user-dropdown" data-qa-selector="user_menu" variant="link" no-caret>
        <template #button-content>
          <gl-avatar
            :entity-name="sidebarData.name"
            :src="sidebarData.avatar_url"
            :size="32"
            data-qa-selector="user_avatar_content"
          />
        </template>
        <new-nav-toggle :endpoint="toggleNewNavEndpoint" enabled />
      </gl-dropdown>
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
          tabindex="-1"
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
      />
    </div>
  </div>
</template>
