<script>
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { buildRedirectConfig } from '~/groups_projects/actions';

export default {
  name: 'GroupActionsApp',
  components: {
    GroupListItemActions,
  },
  props: {
    group: {
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
      const deleteScheduledMessage = sprintf(__('%{group_name} moved to pending deletion.'), {
        group_name: this.group.name,
      });

      const deleteMessage = sprintf(__('%{group_name} is being deleted.'), {
        group_name: this.group.name,
      });

      const leaveMessage = sprintf(__('You left the "%{group_name}" group.'), {
        group_name: this.group.fullName,
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
      const { alerts = [], path = this.group.fullPath } = this.redirectConfig[action] || {};
      const url = new URL(path, window.location.origin);

      visitUrlWithAlerts(url.href, alerts);
    },
  },
};
</script>

<template>
  <group-list-item-actions id="group-more-action-dropdown" :group="group" @action="handleAction" />
</template>
