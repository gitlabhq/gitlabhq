<script>
import SidebarHeader from './sidebar/sidebar_header.vue';
import SidebarTodo from './sidebar/sidebar_todo.vue';
import SidebarStatus from './sidebar/sidebar_status.vue';

export default {
  components: {
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
  methods: {
    handleAlertSidebarError(errorMessage) {
      this.$emit('alert-sidebar-error', errorMessage);
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
        @alert-sidebar-error="handleAlertSidebarError"
      />
      <!-- TODO: Remove after adding extra attribute blocks to sidebar -->
      <div class="block"></div>
    </div>
  </aside>
</template>
