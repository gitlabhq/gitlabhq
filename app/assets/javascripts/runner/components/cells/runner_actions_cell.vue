<script>
import { GlButton, GlButtonGroup, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { __, s__, sprintf } from '~/locale';
import runnerDeleteMutation from '~/runner/graphql/runner_delete.mutation.graphql';
import runnerActionsUpdateMutation from '~/runner/graphql/runner_actions_update.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerEditButton from '../runner_edit_button.vue';
import RunnerDeleteModal from '../runner_delete_modal.vue';

const I18N_PAUSE = __('Pause');
const I18N_RESUME = __('Resume');
const I18N_DELETE = s__('Runners|Delete runner');
const I18N_DELETED_TOAST = s__('Runners|Runner %{name} was deleted');

export default {
  name: 'RunnerActionsCell',
  components: {
    GlButton,
    GlButtonGroup,
    RunnerEditButton,
    RunnerDeleteModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      updating: false,
      deleting: false,
    };
  },
  computed: {
    isActive() {
      return this.runner.active;
    },
    toggleActiveIcon() {
      return this.isActive ? 'pause' : 'play';
    },
    toggleActiveTitle() {
      if (this.updating) {
        // Prevent a "sticky" tooltip: If this button is disabled,
        // mouseout listeners don't run leaving the tooltip stuck
        return '';
      }
      return this.isActive ? I18N_PAUSE : I18N_RESUME;
    },
    deleteTitle() {
      if (this.deleting) {
        // Prevent a "sticky" tooltip: If this button is disabled,
        // mouseout listeners don't run leaving the tooltip stuck
        return '';
      }
      return I18N_DELETE;
    },
    runnerId() {
      return getIdFromGraphQLId(this.runner.id);
    },
    runnerName() {
      return `#${this.runnerId} (${this.runner.shortSha})`;
    },
    runnerDeleteModalId() {
      return `delete-runner-modal-${this.runnerId}`;
    },
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
    },
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
  },
  methods: {
    async onToggleActive() {
      this.updating = true;
      try {
        const toggledActive = !this.runner.active;

        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerActionsUpdateMutation,
          variables: {
            input: {
              id: this.runner.id,
              active: toggledActive,
            },
          },
        });

        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
      } catch (e) {
        this.onError(e);
      } finally {
        this.updating = false;
      }
    },

    async onDelete() {
      // Deleting stays "true" until this row is removed,
      // should only change back if the operation fails.
      this.deleting = true;
      try {
        const {
          data: {
            runnerDelete: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerDeleteMutation,
          variables: {
            input: {
              id: this.runner.id,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: ['getRunners', 'getGroupRunners'],
        });
        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        } else {
          // Use $root to have the toast message stay after this element is removed
          this.$root.$toast?.show(sprintf(I18N_DELETED_TOAST, { name: this.runnerName }));
        }
      } catch (e) {
        this.deleting = false;
        this.onError(e);
      }
    },

    onError(error) {
      const { message } = error;
      createAlert({ message });

      this.reportToSentry(error);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  I18N_DELETE,
};
</script>

<template>
  <gl-button-group>
    <!--
      This button appears for administrators: those with
      access to the adminUrl. More advanced permissions policies
      will allow more granular permissions.

      See https://gitlab.com/gitlab-org/gitlab/-/issues/334802
    -->
    <runner-edit-button v-if="canUpdate && runner.editAdminUrl" :href="runner.editAdminUrl" />
    <gl-button
      v-if="canUpdate"
      v-gl-tooltip.hover.viewport="toggleActiveTitle"
      :aria-label="toggleActiveTitle"
      :icon="toggleActiveIcon"
      :loading="updating"
      data-testid="toggle-active-runner"
      @click="onToggleActive"
    />
    <gl-button
      v-if="canDelete"
      v-gl-tooltip.hover.viewport="deleteTitle"
      v-gl-modal="runnerDeleteModalId"
      :aria-label="deleteTitle"
      icon="close"
      :loading="deleting"
      variant="danger"
      data-testid="delete-runner"
    />

    <runner-delete-modal
      v-if="canDelete"
      :ref="runnerDeleteModalId"
      :modal-id="runnerDeleteModalId"
      :runner-name="runnerName"
      @primary="onDelete"
    />
  </gl-button-group>
</template>
