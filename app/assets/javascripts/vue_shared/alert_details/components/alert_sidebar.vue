<script>
import sidebarStatusQuery from '../graphql/queries/alert_sidebar_status.query.graphql';
import SidebarAssignees from './sidebar/sidebar_assignees.vue';
import SidebarHeader from './sidebar/sidebar_header.vue';
import SidebarStatus from './sidebar/sidebar_status.vue';
import SidebarTodo from './sidebar/sidebar_todo.vue';

export default {
  components: {
    SidebarAssignees,
    SidebarHeader,
    SidebarTodo,
    SidebarStatus,
  },
  inject: {
    projectPath: {
      default: '',
    },
    projectId: {
      default: '',
    },
  },
  props: {
    alert: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    sidebarStatus: {
      query: sidebarStatusQuery,
    },
  },
  data() {
    return {
      sidebarStatus: false,
    };
  },
  computed: {
    sidebarCollapsedClass() {
      return this.sidebarStatus ? 'right-sidebar-collapsed' : 'right-sidebar-expanded';
    },
  },
};
</script>

<template>
  <aside :class="sidebarCollapsedClass" class="right-sidebar alert-sidebar">
    <div class="issuable-sidebar js-issuable-update">
      <sidebar-header
        :sidebar-collapsed="sidebarStatus"
        :project-path="projectPath"
        :alert="alert"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-error="$emit('alert-error', $event)"
      />
      <sidebar-todo
        v-if="sidebarStatus"
        :project-path="projectPath"
        :alert="alert"
        :sidebar-collapsed="sidebarStatus"
        @alert-error="$emit('alert-error', $event)"
      />
      <sidebar-status
        :project-path="projectPath"
        :alert="alert"
        :sidebar-collapsed="sidebarStatus"
        text-class="gl-text-subtle"
        class="gl-w-7/10"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-error="$emit('alert-error', $event)"
      />
      <sidebar-assignees
        :project-path="projectPath"
        :project-id="projectId"
        :alert="alert"
        :sidebar-collapsed="sidebarStatus"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-error="$emit('alert-error', $event)"
      />
      <div class="block"></div>
    </div>
  </aside>
</template>
