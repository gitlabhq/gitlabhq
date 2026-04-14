<script>
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { buildRedirectConfig } from '~/groups_projects/actions';

export default {
  name: 'ProjectHeaderActions',
  components: {
    ProjectListItemActions,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    dashboardPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    redirectConfig() {
      const deleteScheduledMessage = sprintf(__('%{project_name} moved to pending deletion.'), {
        project_name: this.project.name,
      });

      const deleteMessage = sprintf(__('%{project_name} is being deleted.'), {
        project_name: this.project.name,
      });

      const leaveMessage = sprintf(s__('Projects|You left the "%{nameWithNamespace}" project.'), {
        nameWithNamespace: this.project.nameWithNamespace,
      });

      return buildRedirectConfig({
        path: this.dashboardPath,
        deleteScheduledMessage,
        deleteMessage,
        leaveMessage,
      });
    },
  },
  methods: {
    handleAction(action) {
      const { alerts = [], path = this.project.fullPath } = this.redirectConfig[action] || {};
      const url = new URL(path, window.location.origin);

      visitUrlWithAlerts(url.href, alerts);
    },
  },
};
</script>

<template>
  <project-list-item-actions
    id="project-more-action-dropdown"
    :project="project"
    @action="handleAction"
  />
</template>
