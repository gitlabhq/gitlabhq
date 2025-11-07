<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { archiveProject, restoreProject, unarchiveProject, deleteProject } from '~/rest_api';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';
import {
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { InternalEvents } from '~/tracking';
import {
  renderArchiveSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
  renderDeleteSuccessToast,
  deleteParams,
} from './utils';

export default {
  name: 'ProjectListItemActions',
  components: {
    GlLoadingIcon,
    ListActions,
    DeleteModal,
  },
  mixins: [InternalEvents.mixin()],
  i18n: {
    project: __('Project'),
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      actionsLoading: false,
      isDeleteModalVisible: false,
      isDeleteLoading: false,
    };
  },
  computed: {
    actions() {
      return {
        [ACTION_EDIT]: {
          href: this.project.editPath,
        },
        [ACTION_ARCHIVE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.archive,
              errorMessage: s__(
                'Projects|An error occurred archiving the project. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_UNARCHIVE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.unarchive,
              errorMessage: s__(
                'Projects|An error occurred unarchiving the project. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_RESTORE]: {
          action: () =>
            this.onActionWithLoading({
              action: this.restore,
              errorMessage: s__(
                'Projects|An error occurred restoring the project. Please refresh the page to try again.',
              ),
            }),
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
        [ACTION_DELETE_IMMEDIATELY]: {
          action: this.onActionDelete,
        },
      };
    },
    hasActionDelete() {
      return (
        this.project.availableActions?.includes(ACTION_DELETE) ||
        this.project.availableActions?.includes(ACTION_DELETE_IMMEDIATELY)
      );
    },
  },
  methods: {
    async archive() {
      await archiveProject(this.project.id);
      this.$emit('refetch');
      renderArchiveSuccessToast(this.project);

      this.trackEvent('archive_namespace_in_quick_action', {
        label: RESOURCE_TYPES.PROJECT,
        property: 'archive',
      });
    },
    async unarchive() {
      await unarchiveProject(this.project.id);
      this.$emit('refetch');
      renderUnarchiveSuccessToast(this.project);

      this.trackEvent('archive_namespace_in_quick_action', {
        label: RESOURCE_TYPES.PROJECT,
        property: 'unarchive',
      });
    },
    async restore() {
      await restoreProject(this.project.id);
      this.$emit('refetch');
      renderRestoreSuccessToast(this.project);
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
    async onDeleteModalPrimary() {
      this.isDeleteLoading = true;

      try {
        await deleteProject(this.project.id, deleteParams(this.project));
        this.$emit('refetch');
        renderDeleteSuccessToast(this.project);
      } catch (error) {
        createAlert({
          message: s__(
            'Projects|An error occurred deleting the project. Please refresh the page to try again.',
          ),
          error,
          captureError: true,
        });
      } finally {
        this.isDeleteLoading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="actionsLoading" size="sm" class="gl-px-3" />
    <list-actions
      v-else
      data-testid="projects-list-item-actions"
      :actions="actions"
      :available-actions="project.availableActions"
    />
    <delete-modal
      v-if="hasActionDelete"
      v-model="isDeleteModalVisible"
      :confirm-phrase="project.fullPath"
      :name-with-namespace="project.nameWithNamespace"
      :is-fork="project.isForked"
      :confirm-loading="isDeleteLoading"
      :merge-requests-count="project.openMergeRequestsCount"
      :issues-count="project.openIssuesCount"
      :forks-count="project.forksCount"
      :stars-count="project.starCount"
      :marked-for-deletion="project.markedForDeletion"
      :permanent-deletion-date="project.permanentDeletionDate"
      @primary="onDeleteModalPrimary"
    />
  </div>
</template>
