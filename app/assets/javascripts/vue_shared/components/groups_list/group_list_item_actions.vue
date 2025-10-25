<script>
import { GlLoadingIcon } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
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
import { InternalEvents } from '~/tracking';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import axios from '~/lib/utils/axios_utils';
import {
  renderArchiveSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
  renderDeleteSuccessToast,
  deleteParams,
} from './utils';

export default {
  name: 'GroupListItemActions',
  components: {
    GlLoadingIcon,
    ListActions,
    GroupListItemLeaveModal,
    GroupListItemPreventDeleteModal,
    GroupListItemDeleteModal,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      actionsLoading: false,
      isDeleteModalVisible: false,
      isDeleteModalLoading: false,
      isLeaveModalVisible: false,
      leaveModalId: uniqueId('groups-list-item-leave-modal-id-'),
      deleteModalId: uniqueId('groups-list-item-delete-modal-id-'),
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
          text: __('Leave group'),
          action: this.onActionLeave,
        },
      };
    },
    hasActionDelete() {
      return (
        this.group.availableActions?.includes(ACTION_DELETE) ||
        this.group.availableActions?.includes(ACTION_DELETE_IMMEDIATELY)
      );
    },
    hasActionLeave() {
      return this.group.availableActions?.includes(ACTION_LEAVE);
    },
  },
  methods: {
    refetch() {
      this.$emit('refetch');
    },
    async archive() {
      await archiveGroup(this.group.id);
      this.refetch();
      renderArchiveSuccessToast(this.group);

      this.trackEvent('archive_namespace_in_quick_action', {
        label: RESOURCE_TYPES.GROUP,
        property: 'archive',
      });
    },
    async unarchive() {
      await unarchiveGroup(this.group.id);
      this.refetch();
      renderUnarchiveSuccessToast(this.group);

      this.trackEvent('archive_namespace_in_quick_action', {
        label: RESOURCE_TYPES.GROUP,
        property: 'unarchive',
      });
    },
    async restore() {
      await restoreGroup(this.group.id);
      this.refetch();
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
      this.isDeleteModalVisible = true;
    },
    onDeleteModalChange(isVisible) {
      this.isDeleteModalVisible = isVisible;
    },
    async onDeleteModalConfirm() {
      this.isDeleteModalLoading = true;

      try {
        await axios.delete(this.group.relativeWebUrl, {
          params: deleteParams(this.group),
        });
        this.refetch();
        renderDeleteSuccessToast(this.group);
      } catch (error) {
        createAlert({
          message: __(
            'An error occurred deleting the group. Please refresh the page to try again.',
          ),
          error,
          captureError: true,
        });
      } finally {
        this.isDeleteModalLoading = false;
      }
    },
    onActionLeave() {
      this.isLeaveModalVisible = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="actionsLoading" size="sm" class="gl-p-3" />
    <list-actions
      v-else
      data-testid="groups-list-item-actions"
      :actions="actions"
      :available-actions="availableActions"
    />
    <template v-if="hasActionDelete">
      <group-list-item-prevent-delete-modal
        v-if="group.isLinkedToSubscription"
        :visible="isDeleteModalVisible"
        :modal-id="deleteModalId"
        @change="onDeleteModalChange"
      />
      <group-list-item-delete-modal
        v-else
        :visible="isDeleteModalVisible"
        :modal-id="deleteModalId"
        :phrase="group.fullName"
        :confirm-loading="isDeleteModalLoading"
        :group="group"
        @confirm.prevent="onDeleteModalConfirm"
        @change="onDeleteModalChange"
      />
    </template>

    <template v-if="hasActionLeave">
      <group-list-item-leave-modal
        v-model="isLeaveModalVisible"
        :modal-id="leaveModalId"
        :group="group"
        @success="refetch"
      />
    </template>
  </div>
</template>
