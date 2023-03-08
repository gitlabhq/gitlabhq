<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import runnerDeleteMutation from '~/ci/runner/graphql/shared/runner_delete.mutation.graphql';
import { createAlert } from '~/alert';
import { sprintf, s__ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';
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
      // Only show basic "delete" tooltip when compact.
      // Also prevent a "sticky" tooltip: If this button is
      // loading, mouseout listeners don't run leaving the tooltip stuck
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
      const title = sprintf(s__('Runners|Runner %{runnerName} failed to delete'), {
        runnerName: this.runnerName,
      });

      createAlert({ title, message });
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>

<template>
  <div v-gl-tooltip="tooltip" class="btn-group">
    <gl-button
      v-gl-modal="runnerDeleteModalId"
      :aria-label="ariaLabel"
      :icon="icon"
      :class="buttonClass"
      :loading="deleting"
      variant="danger"
      category="secondary"
      v-bind="$attrs"
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
