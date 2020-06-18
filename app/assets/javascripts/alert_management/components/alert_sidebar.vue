<script>
import SidebarHeader from './sidebar/sidebar_header.vue';
import SidebarTodo from './sidebar/sidebar_todo.vue';
import SidebarStatus from './sidebar/sidebar_status.vue';
import SidebarAssignees from './sidebar/sidebar_assignees.vue';

export default {
  components: {
    SidebarAssignees,
    SidebarHeader,
    SidebarTodo,
    SidebarStatus,
  },
  props: {
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    alert: {
      type: Object,
      required: true,
    },
  },
  computed: {
    sidebarCollapsedClass() {
      return this.sidebarCollapsed ? 'right-sidebar-collapsed' : 'right-sidebar-expanded';
    },
  },
};
</script>

<template>
  <aside :class="sidebarCollapsedClass" class="right-sidebar alert-sidebar">
    <div class="issuable-sidebar js-issuable-update">
      <sidebar-header
        :sidebar-collapsed="sidebarCollapsed"
        @toggle-sidebar="$emit('toggle-sidebar')"
      />
      <sidebar-todo v-if="sidebarCollapsed" :sidebar-collapsed="sidebarCollapsed" />
      <sidebar-status
        :project-path="projectPath"
        :alert="alert"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-sidebar-error="$emit('alert-sidebar-error', $event)"
      />
      <sidebar-assignees
        :project-path="projectPath"
        :alert="alert"
        :sidebar-collapsed="sidebarCollapsed"
        @alert-refresh="$emit('alert-refresh')"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-sidebar-error="$emit('alert-sidebar-error', $event)"
      />
      <div class="block"></div>
    </div>
  </aside>
</template>
