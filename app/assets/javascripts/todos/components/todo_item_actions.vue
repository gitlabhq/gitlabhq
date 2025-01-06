<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { INSTRUMENT_TODO_ITEM_CLICK, TODO_STATE_DONE, TODO_STATE_PENDING } from '../constants';
import markAsDoneMutation from './mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from './mutations/mark_as_pending.mutation.graphql';
import unSnoozeTodoMutation from './mutations/un_snooze_todo.mutation.graphql';
import SnoozeTodoDropdown from './snooze_todo_dropdown.vue';

export default {
  components: {
    SnoozeTodoDropdown,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
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
    showSnoozingDropdown() {
      return this.glFeatures.todosSnoozing && !this.isSnoozed && this.isPending;
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
          this.$emit('change', this.todo.id, this.isDone);
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        showError();
      }
    },
    async unSnooze() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: unSnoozeTodoMutation,
          variables: {
            todoId: this.todo.id,
          },
          optimisticResponse: {
            todoUnSnooze: {
              todo: {
                id: this.todo.id,
                snoozedUntil: null,
                __typename: 'Todo',
              },
              errors: [],
            },
          },
        });

        if (data.errors?.length > 0) {
          reportToSentry(this.$options.name, new Error(data.errors.join(', ')));
          this.showUnSnoozedError();
        } else {
          this.$emit('change', this.todo.id, this.isDone);
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        this.showUnSnoozedError();
      }
    },
    showUnSnoozedError() {
      this.$toast.show(s__('Todos|Failed to un-snooze todo. Try again later.'), {
        variant: 'danger',
      });
    },
  },
  i18n: {
    markAsPending: s__('Todos|Undo'),
    markAsDone: s__('Todos|Mark as done'),
    unSnooze: s__('Todos|Remove snooze'),
  },
};
</script>

<template>
  <div @click.prevent>
    <gl-button
      v-if="glFeatures.todosSnoozing && isSnoozed"
      v-gl-tooltip
      icon="time-out"
      :title="$options.i18n.unSnooze"
      :aria-label="$options.i18n.unSnooze"
      data-testid="un-snooze-button"
      @click="unSnooze"
    />
    <snooze-todo-dropdown v-else-if="showSnoozingDropdown" :todo="todo" />
    <gl-button
      v-gl-tooltip.hover
      :icon="isDone ? 'redo' : 'check'"
      :aria-label="isDone ? $options.i18n.markAsPending : $options.i18n.markAsDone"
      :title="tooltipTitle"
      @click="toggleStatus"
    />
  </div>
</template>
