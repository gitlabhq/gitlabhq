<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK } from '~/todos/constants';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import { snoozeTodo } from '../utils';
import unSnoozeTodoMutation from './mutations/un_snooze_todo.mutation.graphql';
import SnoozeTimePicker from './todo_snooze_until_picker.vue';

export default {
  components: {
    GlButton,
    SnoozeTimePicker,
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
    isPending: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showSnoozingDropdown() {
      return !this.isSnoozed && this.isPending;
    },
  },
  methods: {
    async snooze(until) {
      try {
        const { data } = await snoozeTodo(this.$apollo, this.todo, until);

        if (data.errors?.length) {
          throw new Error(data.errors.join(', '));
        } else {
          this.$emit('snoozed');
        }
      } catch (error) {
        reportToSentry(this.$options.name, error);
        this.showError(this.$options.i18n.snoozeError);
      }
    },
    async unSnooze() {
      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: 'remove_snooze',
      });
      try {
        const { data } = await this.$apollo.mutate({
          mutation: unSnoozeTodoMutation,
          variables: {
            todoId: this.todo.id,
          },
          optimisticResponse: () => {
            updateGlobalTodoCount(+1);

            return {
              todoUnSnooze: {
                todo: {
                  id: this.todo.id,
                  snoozedUntil: null,
                  __typename: 'Todo',
                },
                errors: [],
              },
            };
          },
        });

        if (data.errors?.length > 0) {
          throw new Error(data.errors.join(', '));
        } else {
          this.$emit('un-snoozed');
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        this.showError(this.$options.i18n.unSnoozeError);
      }
    },
    showError(message) {
      this.$toast.show(message, {
        variant: 'danger',
      });
    },
  },
  i18n: {
    snoozeError: s__('Todos|Failed to snooze todo. Try again later.'),
    unSnooze: s__('Todos|Remove snooze'),
    unSnoozeError: s__('Todos|Failed to un-snooze todo. Try again later.'),
  },
};
</script>

<template>
  <span>
    <gl-button
      v-if="isSnoozed"
      v-gl-tooltip
      icon="time-out"
      :title="$options.i18n.unSnooze"
      :aria-label="$options.i18n.unSnooze"
      data-testid="un-snooze-button"
      @click="unSnooze"
    />
    <snooze-time-picker v-else-if="showSnoozingDropdown" @snooze-until="(until) => snooze(until)" />
  </span>
</template>
