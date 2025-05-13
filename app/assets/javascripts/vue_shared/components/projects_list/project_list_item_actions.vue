<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { restoreProject } from '~/rest_api';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
} from '~/vue_shared/components/list_actions/constants';
import { renderRestoreSuccessToast } from './utils';

export default {
  name: 'ProjectListItemActions',
  i18n: {
    project: __('Project'),
    restoreErrorMessage: s__(
      'Projects|An error occurred restoring the project. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    ListActions,
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
        [ACTION_RESTORE]: {
          action: this.onActionRestore,
        },
        [ACTION_DELETE]: {
          action: this.onActionDelete,
        },
      };
    },
  },
  methods: {
    async onActionRestore() {
      this.actionsLoading = true;

      try {
        await restoreProject(this.project.id);
        this.$emit('refetch');
        renderRestoreSuccessToast(this.project, this.$options.i18n.project);
      } catch (error) {
        createAlert({ message: this.$options.i18n.restoreErrorMessage, error, captureError: true });
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
  <list-actions v-else :actions="actions" :available-actions="project.availableActions" />
</template>
