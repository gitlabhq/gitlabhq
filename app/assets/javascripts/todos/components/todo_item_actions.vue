<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import { s__ } from '~/locale';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '../constants';
import markAsDoneMutation from './mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from './mutations/mark_as_pending.mutation.graphql';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    todo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
    },
    isPending() {
      return this.todo.state === TODO_STATE_PENDING;
    },
  },
  methods: {
    showMarkAsDoneError() {
      const toastProps = {
        text: s__('Todos|Mark as done failed. Try again later.'),
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    showMarkAsPendingError() {
      const toastProps = {
        text: s__('Todos|Failed adding todo. Try again later.'),
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    async toggleStatus() {
      const mutation = this.isDone ? markAsPendingMutation : markAsDoneMutation;
      const showError = this.isDone ? this.showMarkAsPendingError : this.showMarkAsDoneError;

      try {
        this.isLoading = true;

        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            todoId: this.todo.id,
          },
        });

        if (data.errors?.length > 0) {
          reportToSentry(this.$options.name, new Error(data.errors.join(', ')));
          showError();
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        showError();
      } finally {
        this.isLoading = false;
      }
    },
  },
  i18n: {
    markAsPending: s__('Todos|Undo'),
    markAsDone: s__('Todos|Mark as done'),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    :icon="isDone ? 'redo' : 'check'"
    :loading="isLoading"
    :aria-label="isDone ? $options.i18n.markAsPending : $options.i18n.markAsDone"
    :title="isDone ? $options.i18n.markAsPending : $options.i18n.markAsDone"
    @click.prevent="toggleStatus"
  />
</template>
