<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import runnerDeleteMutation from '~/runner/graphql/shared/runner_delete.mutation.graphql';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
import { captureException } from '~/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { I18N_DELETE_RUNNER, I18N_DELETED_TOAST } from '../constants';
import RunnerDeleteModal from './runner_delete_modal.vue';

export default {
  name: 'RunnerDeleteButton',
  components: {
    GlButton,
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
      validator: (runner) => {
        return runner?.id && runner?.shortSha;
      },
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['deleted'],
  data() {
    return {
      deleting: false,
    };
  },
  computed: {
    runnerId() {
      return getIdFromGraphQLId(this.runner.id);
    },
    runnerName() {
      return `#${this.runnerId} (${this.runner.shortSha})`;
    },
    runnerDeleteModalId() {
      return `delete-runner-modal-${this.runnerId}`;
    },
    icon() {
      if (this.compact) {
        return 'close';
      }
      return '';
    },
    buttonContent() {
      if (this.compact) {
        return null;
      }
      return I18N_DELETE_RUNNER;
    },
    buttonClass() {
      // Ensure a square button is shown when compact: true.
      // Without this class we will have distorted/rectangular button.
      if (this.compact) {
        return 'btn-icon';
      }
      return null;
    },
    ariaLabel() {
      if (this.compact) {
        return I18N_DELETE_RUNNER;
      }
      return null;
    },
    tooltip() {
      // Only show tooltip when compact.
      // Also prevent a "sticky" tooltip: If this button is
      // disabled, mouseout listeners don't run leaving the tooltip stuck
      if (this.compact && !this.deleting) {
        return I18N_DELETE_RUNNER;
      }
      return '';
    },
  },
  methods: {
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
        });
        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        } else {
          this.$emit('deleted', {
            message: sprintf(I18N_DELETED_TOAST, { name: this.runnerName }),
          });
        }
      } catch (e) {
        this.deleting = false;
        this.onError(e);
      }
    },
    onError(error) {
      const { message } = error;

      createAlert({ message });
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover.viewport="tooltip"
    v-gl-modal="runnerDeleteModalId"
    :aria-label="ariaLabel"
    :icon="icon"
    :class="buttonClass"
    :loading="deleting"
    variant="danger"
  >
    {{ buttonContent }}
    <runner-delete-modal
      :modal-id="runnerDeleteModalId"
      :runner-name="runnerName"
      @primary="onDelete"
    />
  </gl-button>
</template>
