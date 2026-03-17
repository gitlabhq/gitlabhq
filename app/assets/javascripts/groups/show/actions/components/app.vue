<script>
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import { visitUrl, visitUrlWithAlerts } from '~/lib/utils/url_utility';
import {
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import { __, sprintf } from '~/locale';

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
      return {
        [ACTION_DELETE_IMMEDIATELY]: {
          path: this.dashboardPath,
          alerts: [
            {
              id: 'group-overview-delete-success',
              message: sprintf(__('%{group_name} is being deleted.'), {
                group_name: this.group.fullName,
              }),
              variant: 'info',
            },
          ],
        },
        [ACTION_LEAVE]: {
          path: this.dashboardPath,
          alerts: [
            {
              id: 'group-overview-leave-success',
              message: sprintf(__('You left the "%{group_name}" group.'), {
                group_name: this.group.fullName,
              }),
              variant: 'info',
            },
          ],
        },
      };
    },
  },
  methods: {
    handleAction(action) {
      const { alerts, path = this.group.fullPath } = this.redirectConfig[action] || {};
      const url = new URL(path, window.location.origin);

      if (alerts) {
        visitUrlWithAlerts(url.href, alerts);
      } else {
        visitUrl(url.href);
      }
    },
  },
};
</script>

<template>
  <group-list-item-actions id="group-more-action-dropdown" :group="group" @action="handleAction" />
</template>
