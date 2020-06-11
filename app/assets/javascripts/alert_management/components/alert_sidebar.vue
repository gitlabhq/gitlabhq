<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagsMixin()],
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
        v-if="glFeatures.alertAssignee"
        :project-path="projectPath"
        :alert="alert"
        @toggle-sidebar="$emit('toggle-sidebar')"
        @alert-sidebar-error="$emit('alert-sidebar-error', $event)"
      />
      <!-- TODO: Remove after adding extra attribute blocks to sidebar -->
      <div class="block"></div>
    </div>
  </aside>
</template>
