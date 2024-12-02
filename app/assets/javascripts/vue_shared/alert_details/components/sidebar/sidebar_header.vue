<script>
import ToggleSidebar from '~/sidebar/components/toggle/toggle_sidebar.vue';
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
  <div class="block gl-flex gl-justify-between !gl-border-b-default">
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
