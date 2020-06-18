<script>
import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
import SidebarTodo from './sidebar_todo.vue';

export default {
  components: {
    ToggleSidebar,
    SidebarTodo,
  },
  props: {
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="block  d-flex justify-content-between">
    <span class="issuable-header-text hide-collapsed">
      {{ __('Quick actions') }}
    </span>
    <toggle-sidebar
      :collapsed="sidebarCollapsed"
      css-classes="ml-auto"
      @toggle="$emit('toggle-sidebar')"
    />
    <!-- TODO: Implement after or as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/215946 -->
    <template v-if="false">
      <sidebar-todo v-if="!sidebarCollapsed" :sidebar-collapsed="sidebarCollapsed" />
    </template>
  </div>
</template>
