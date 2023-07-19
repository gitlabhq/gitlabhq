<script>
import runnerDeleteMutation from '~/ci/runner/graphql/shared/runner_delete.mutation.graphql';
import { createAlert } from '~/alert';
import { sprintf, s__ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { I18N_DELETED_TOAST } from '../constants';
import RunnerDeleteModal from './runner_delete_modal.vue';

/**
 * Component that wraps a delete GraphQL mutation for the
 * runner, given its id.
 *
 * You can use the slot to define a presentation for the
 * delete action, like a button or dropdown item.
 *
 * Usage:
 *
 * ```vue
 * <runner-delete-action
 *   #default="{ loading, onClick }"
 *   :runner="runner"
 *   @done="onDeleted"
 * >
 *   <button :disabled="loading" @click="onClick"> Delete! </button>
 * </runner-pause-action>
 * ```
 *
 */
export default {
  name: 'RunnerDeleteAction',
  components: {
    RunnerDeleteModal,
  },
  props: {
    runner: {
      type: Object,
      required: true,
      validator: (runner) => {
        return runner?.id && runner?.shortSha;
      },
    },
  },
  emits: ['done'],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    runnerId() {
      return getIdFromGraphQLId(this.runner.id);
    },
    runnerName() {
      return `#${this.runnerId} (${this.runner.shortSha})`;
    },
    runnerManagersCount() {
      return this.runner.managers?.count || 0;
    },
    runnerDeleteModalId() {
      return `delete-runner-modal-${this.runnerId}`;
    },
  },
  methods: {
    onClick() {
      this.$refs.modal.show();
    },
    async onDelete() {
      // "loading" stays "true" until this row is removed,
      // should only change back if the operation fails.
      this.loading = true;
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

            this.$emit('done', {
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
      this.loading = false;
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
  <div>
    <slot :loading="loading" :on-click="onClick"></slot>
    <runner-delete-modal
      ref="modal"
      :modal-id="runnerDeleteModalId"
      :runner-name="runnerName"
      :managers-count="runnerManagersCount"
      @primary="onDelete"
    />
  </div>
</template>
