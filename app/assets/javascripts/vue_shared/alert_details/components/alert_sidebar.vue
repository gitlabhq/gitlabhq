<script>
import SidebarAssignees from './sidebar/sidebar_assignees.vue';
import SidebarStatus from './sidebar/sidebar_status.vue';

export default {
  name: 'AlertSidebar',
  components: {
    SidebarAssignees,
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
  emits: ['alert-error'],
};
</script>

<template>
  <div class="js-issuable-update gl-space-y-5" data-testid="alert-sidebar">
    <sidebar-status
      class="gl-border-b gl-pb-5"
      :project-path="projectPath"
      :alert="alert"
      @alert-error="$emit('alert-error', $event)"
    />
    <sidebar-assignees
      class="gl-border-b gl-pb-5"
      :project-path="projectPath"
      :project-id="projectId"
      :alert="alert"
      @alert-error="$emit('alert-error', $event)"
    />
  </div>
</template>
