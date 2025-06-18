<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import { restoreGroup } from '~/api/groups_api';
import { renderRestoreSuccessToast } from './utils';

export default {
  name: 'GroupListItemActions',
  i18n: {
    restoreErrorMessage: __(
      'An error occurred restoring this group. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    ListActions,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      actionsLoading: false,
    };
  },
  computed: {
    availableActions() {
      return this.group.availableActions ?? [];
    },
    actions() {
      return {
        [ACTION_EDIT]: {
          href: this.group.editPath,
        },
        [ACTION_RESTORE]: {
          action: this.onActionRestore,
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
        [ACTION_LEAVE]: {
          action: this.onActionLeave,
        },
      };
    },
  },
  methods: {
    async onActionRestore() {
      this.actionsLoading = true;

      try {
        await restoreGroup(this.group.id);
        this.$emit('refetch');
        renderRestoreSuccessToast(this.group);
      } catch (error) {
        createAlert({ message: this.$options.i18n.restoreErrorMessage, error, captureError: true });
      } finally {
        this.actionsLoading = false;
      }
    },
    onActionDelete() {
      this.$emit('delete');
    },
    onActionLeave() {
      this.$emit('leave');
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="actionsLoading" size="sm" class="gl-p-3" />
  <list-actions
    v-else
    data-testid="groups-projects-more-actions-dropdown"
    :actions="actions"
    :available-actions="availableActions"
  />
</template>
