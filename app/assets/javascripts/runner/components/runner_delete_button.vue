<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import runnerDeleteMutation from '~/runner/graphql/shared/runner_delete.mutation.graphql';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
import { captureException } from '~/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  I18N_DELETE_DISABLED_MANY_PROJECTS,
  I18N_DELETE_DISABLED_UNKNOWN_REASON,
  I18N_DELETE_RUNNER,
  I18N_DELETED_TOAST,
} from '../constants';
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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
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
      if (this.disabled && this.runner.projectCount > 1) {
        return I18N_DELETE_DISABLED_MANY_PROJECTS;
      }
      if (this.disabled) {
        return I18N_DELETE_DISABLED_UNKNOWN_REASON;
      }

      // Only show basic "delete" tooltip when compact.
      // Also prevent a "sticky" tooltip: If this button is
      // disabled, mouseout listeners don't run leaving the tooltip stuck
      if (this.compact && !this.deleting) {
        return I18N_DELETE_RUNNER;
      }
      return '';
    },
    wrapperTabindex() {
      if (this.disabled) {
        // Trigger tooltip on keyboard-focusable wrapper
        // See https://bootstrap-vue.org/docs/directives/tooltip
        return '0';
      }
      return null;
    },
  },
  methods: {
    async onDelete() {
      // Deleting stays "true" until this row is removed,
      // should only change back if the operation fails.
      this.deleting = true;
      try {
        await this.$apollo.mutate({
          mutation: runnerDeleteMutation,
          variables: {
            input: {
              id: this.runner.id,
            },
          },
          update: (cache, { data }) => {
            const { errors } = data.runnerDelete;

            if (errors?.length) {
              this.onError(new Error(errors.join(' ')));
              return;
            }

            this.$emit('deleted', {
              message: sprintf(I18N_DELETED_TOAST, { name: this.runnerName }),
            });

            // Remove deleted runner from the cache
            const cacheId = cache.identify(this.runner);
            cache.evict({ id: cacheId });
            cache.gc();
          },
        });
      } catch (e) {
        this.onError(e);
      }
    },
    onError(error) {
      this.deleting = false;
      const { message } = error;

      createAlert({ message });
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>

<template>
  <div v-gl-tooltip="tooltip" class="btn-group" :tabindex="wrapperTabindex">
    <gl-button
      v-gl-modal="runnerDeleteModalId"
      :aria-label="ariaLabel"
      :icon="icon"
      :class="buttonClass"
      :loading="deleting"
      :disabled="disabled"
      variant="danger"
    >
      {{ buttonContent }}
    </gl-button>
    <runner-delete-modal
      :modal-id="runnerDeleteModalId"
      :runner-name="runnerName"
      @primary="onDelete"
    />
  </div>
</template>
