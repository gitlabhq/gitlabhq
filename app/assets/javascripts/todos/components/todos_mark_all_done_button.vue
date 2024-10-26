<script>
import { GlButton } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { n__, s__ } from '~/locale';

import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK } from '~/todos/constants';
import markAllAsDoneMutation from './mutations/mark_all_as_done.mutation.graphql';
import undoMarkAllAsDoneMutation from './mutations/undo_mark_all_as_done.mutation.graphql';

export default {
  components: {
    GlButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    async performMutation(mutation, failureMessage) {
      this.isLoading = true;

      try {
        const { data } = await mutation();

        if (data.errors?.length > 0) {
          throw new Error(data.errors.join(', '));
        }
      } catch (failure) {
        Sentry.captureException(failure);
        this.showErrorToast(failureMessage);
      } finally {
        this.isLoading = false;
      }
    },
    async markAllAsDone() {
      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: 'mark_all_as_done',
      });
      return this.performMutation(async () => {
        const resp = await this.$apollo.mutate({
          mutation: markAllAsDoneMutation,
          variables: this.filters,
        });
        const data = resp.data.markAllAsDone;

        if (data.todos) {
          const todoIDs = data.todos.map((todo) => todo.id);
          const message = n__(
            'Todos|Marked 1 to-do as done',
            'Todos|Marked %d to-dos as done',
            todoIDs.length,
          );
          const { hide } = this.$toast.show(message, {
            action: {
              text: s__('Todos|Undo'),
              onClick: () => {
                hide();
                this.undoMarkAllAsDone(todoIDs);
              },
            },
          });
          this.$emit('change');
        }

        return { data };
      }, s__('Todos|Mark all as done failed. Try again later.'));
    },
    undoMarkAllAsDone(todoIDs) {
      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: 'undo_mark_all_as_done',
      });
      this.performMutation(async () => {
        const resp = await this.$apollo.mutate({
          mutation: undoMarkAllAsDoneMutation,
          variables: {
            todoIDs,
          },
        });
        const data = resp.data.undoMarkAllAsDone;

        if (data.todos) {
          const message = n__('Todos|Restored 1 to-do', 'Todos|Restored %d to-dos', todoIDs.length);
          this.$toast.show(message);
          this.$emit('change');
        }

        return { data };
      }, s__('Todos|Could not restore to-dos.'));
    },
    showErrorToast(text) {
      this.$toast.show(text, {
        variant: 'danger',
      });
    },
  },
};
</script>

<template>
  <gl-button data-testid="btn-mark-all-as-done" :loading="isLoading" @click.prevent="markAllAsDone">
    {{ s__('Todos|Mark all as done') }}
  </gl-button>
</template>
