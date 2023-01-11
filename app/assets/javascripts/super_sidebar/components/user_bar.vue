<script>
import { GlAvatar, GlDropdown, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import logo from '../../../../views/shared/_logo.svg';
import Counter from './counter.vue';

export default {
  logo,
  components: {
    GlAvatar,
    GlDropdown,
    GlIcon,
    NewNavToggle,
    Counter,
  },
  i18n: {
    issues: __('Issues'),
    mergeRequests: __('Merge requests'),
    todoList: __('To-Do list'),
  },
  directives: {
    SafeHtml,
  },
  inject: ['rootPath', 'toggleNewNavEndpoint'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="user-bar">
    <div class="gl-display-flex gl-align-items-center gl-px-3 gl-py-2 gl-gap-3">
      <div class="gl-flex-grow-1">
        <a v-safe-html="$options.logo" :href="rootPath"></a>
      </div>
      <gl-dropdown variant="link" no-caret>
        <template #button-content>
          <gl-icon name="plus" class="gl-vertical-align-middle gl-text-black-normal" />
        </template>
      </gl-dropdown>
      <button class="gl-border-none">
        <gl-icon name="search" class="gl-vertical-align-middle" />
      </button>
      <gl-dropdown data-testid="user-dropdown" variant="link" no-caret>
        <template #button-content>
          <gl-avatar :entity-name="sidebarData.name" :src="sidebarData.avatar_url" :size="32" />
        </template>
        <new-nav-toggle :endpoint="toggleNewNavEndpoint" enabled />
      </gl-dropdown>
    </div>
    <div class="gl-display-flex gl-justify-content-space-between gl-px-3 gl-py-2 gl-gap-2">
      <counter
        icon="issues"
        :count="sidebarData.assigned_open_issues_count"
        :href="sidebarData.issues_dashboard_path"
        :label="$options.i18n.issues"
      />
      <counter
        icon="merge-request-open"
        :count="sidebarData.assigned_open_merge_requests_count"
        :label="$options.i18n.mergeRequests"
      />
      <counter
        icon="todo-done"
        :count="sidebarData.todos_pending_count"
        href="/dashboard/todos"
        :label="$options.i18n.todoList"
      />
    </div>
  </div>
</template>
