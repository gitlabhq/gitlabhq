<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { archiveProject, restoreProject, unarchiveProject } from '~/rest_api';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import {
  ACTION_ARCHIVE,
  ACTION_DELETE,
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
} from './utils';

export default {
  name: 'ProjectListItemActions',
  components: {
    GlLoadingIcon,
    ListActions,
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
      };
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
      this.$emit('delete');
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="actionsLoading" size="sm" class="gl-px-3" />
  <list-actions
    v-else
    data-testid="groups-projects-more-actions-dropdown"
    :actions="actions"
    :available-actions="project.availableActions"
  />
</template>
