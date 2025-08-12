<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  destroyUserCountsManager,
  createUserCountsManager,
  userCounts,
  useCachedUserCounts,
} from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import Counter from './counter.vue';
import MergeRequestMenu from './merge_request_menu.vue';

export default {
  name: 'UserCounts',
  components: {
    Counter,
    MergeRequestMenu,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
    counterClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    issues: __('Assigned issues'),
    mergeRequests: __('Merge requests'),
    todoList: __('To-Do List'),
  },
  data() {
    return {
      mrMenuShown: false,
      userCounts,
    };
  },
  computed: {
    mergeRequestMenuComponent() {
      return this.sidebarData.merge_request_menu ? 'merge-request-menu' : 'div';
    },
  },
  created() {
    Object.assign(userCounts, this.sidebarData.user_counts);
    createUserCountsManager();

    if (
      userCounts.assigned_merge_requests === null ||
      userCounts.review_requested_merge_requests === null
    ) {
      useCachedUserCounts();
      fetchUserCounts();
    }
  },
  beforeDestroy() {
    destroyUserCountsManager();
  },
  methods: {
    onMergeRequestMenuShown() {
      this.mrMenuShown = true;
    },
    onMergeRequestMenuHidden() {
      this.mrMenuShown = false;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-justify-between gl-gap-2">
    <counter
      v-gl-tooltip.bottom="$options.i18n.issues"
      class="dashboard-shortcuts-issues gl-basis-1/3"
      icon="issues"
      :class="counterClass"
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
      @shown="onMergeRequestMenuShown"
      @hidden="onMergeRequestMenuHidden"
    >
      <counter
        v-gl-tooltip.bottom="mrMenuShown ? '' : $options.i18n.mergeRequests"
        class="gl-w-full"
        :class="{
          'js-merge-request-dashboard-shortcut': !sidebarData.merge_request_menu,
          [counterClass]: true,
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
      v-gl-tooltip.bottom="$options.i18n.todoList"
      class="shortcuts-todos js-todos-count gl-basis-1/3"
      icon="todo-done"
      :class="counterClass"
      :count="userCounts.todos"
      :href="sidebarData.todos_dashboard_path"
      :label="$options.i18n.todoList"
      data-testid="todos-shortcut-button"
      data-track-action="click_link"
      data-track-label="todos_link"
      data-track-property="nav_core_menu"
    />
  </div>
</template>
