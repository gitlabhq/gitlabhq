<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK, TODO_STATE_DONE, TODO_STATE_PENDING } from '../constants';
import markAsDoneMutation from './mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from './mutations/mark_as_pending.mutation.graphql';
import ToggleSnoozedStatus from './toggle_snoozed_status.vue';

export default {
  components: {
    ToggleSnoozedStatus,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    todo: {
      type: Object,
      required: true,
    },
    isSnoozed: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showToggleSnoozed() {
      return (!this.isSnoozed && this.isPending) || this.isSnoozed;
    },
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
    },
    isPending() {
      return this.todo.state === TODO_STATE_PENDING;
    },
    tooltipTitle() {
      return this.isDone ? this.$options.i18n.markAsPending : this.$options.i18n.markAsDone;
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
      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: this.isDone ? 'mark_pending' : 'mark_done',
      });
      const mutation = this.isDone ? markAsPendingMutation : markAsDoneMutation;
      const showError = this.isDone ? this.showMarkAsPendingError : this.showMarkAsDoneError;

      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            todoId: this.todo.id,
          },
          optimisticResponse: {
            toggleStatus: {
              todo: {
                id: this.todo.id,
                state: this.isDone ? TODO_STATE_PENDING : TODO_STATE_DONE,
                __typename: 'Todo',
              },
              errors: [],
            },
          },
        });

        if (data.errors?.length > 0) {
          reportToSentry(this.$options.name, new Error(data.errors.join(', ')));
          showError();
        } else {
          this.$emit('change');
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        showError();
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
  <div class="gl-flex gl-gap-2">
    <toggle-snoozed-status
      :todo="todo"
      :is-snoozed="isSnoozed"
      :is-pending="isPending"
      @snoozed="$emit('change')"
      @un-snoozed="$emit('change')"
    />
    <gl-button
      v-gl-tooltip.hover
      data-testid="toggle-status-button"
      :icon="isDone ? 'redo' : 'check'"
      :aria-label="isDone ? $options.i18n.markAsPending : $options.i18n.markAsDone"
      :title="tooltipTitle"
      @click="toggleStatus"
    />
  </div>
</template>
