<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import {
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import { archiveGroup, restoreGroup, unarchiveGroup } from '~/api/groups_api';
import {
  renderArchiveSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
} from './utils';

export default {
  name: 'GroupListItemActions',
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
        [ACTION_ARCHIVE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.archive,
              errorMessage: __(
                'An error occurred archiving this group. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_UNARCHIVE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.unarchive,
              errorMessage: __(
                'An error occurred unarchiving this group. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_RESTORE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.restore,
              errorMessage: __(
                'An error occurred restoring this group. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
        [ACTION_DELETE_IMMEDIATELY]: {
          action: this.onActionDelete,
        },
        [ACTION_LEAVE]: {
          action: this.onActionLeave,
        },
      };
    },
  },
  methods: {
    async archive() {
      await archiveGroup(this.group.id);
      this.$emit('refetch');
      renderArchiveSuccessToast(this.group);
    },
    async unarchive() {
      await unarchiveGroup(this.group.id);
      this.$emit('refetch');
      renderUnarchiveSuccessToast(this.group);
    },
    async restore() {
      await restoreGroup(this.group.id);
      this.$emit('refetch');
      renderRestoreSuccessToast(this.group);
    },
    async onActionWithLoading({ action, errorMessage }) {
      this.actionsLoading = true;

      try {
        await action();
      } catch (error) {
        createAlert({ message: errorMessage, error, captureError: true });
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
