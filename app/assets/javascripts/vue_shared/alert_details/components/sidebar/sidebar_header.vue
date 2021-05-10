<script>
import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
import SidebarTodo from './sidebar_todo.vue';

export default {
  components: {
    ToggleSidebar,
    SidebarTodo,
  },
  props: {
    alert: {
      type: Object,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="block gl-display-flex gl-justify-content-space-between gl-border-b-gray-100!">
    <span class="issuable-header-text hide-collapsed">
      {{ __('To Do') }}
    </span>
    <sidebar-todo
      v-if="!sidebarCollapsed"
      :project-path="projectPath"
      :alert="alert"
      :sidebar-collapsed="sidebarCollapsed"
      @alert-error="$emit('alert-error', $event)"
    />
    <toggle-sidebar :collapsed="sidebarCollapsed" @toggle="$emit('toggle-sidebar')" />
  </div>
</template>
