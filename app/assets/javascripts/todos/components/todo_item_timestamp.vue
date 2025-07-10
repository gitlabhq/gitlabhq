<script>
import { isInPast, isToday, newDate } from '~/lib/utils/datetime_utility';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { s__, sprintf } from '~/locale';
import TodoSnoozedTimestamp from './todo_snoozed_timestamp.vue';

export default {
  components: { TodoSnoozedTimestamp },
  mixins: [timeagoMixin],
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
    dueDate() {
      if (!this.todo?.targetEntity?.dueDate) {
        return null;
      }
      return newDate(this.todo.targetEntity.dueDate);
    },
    formattedCreatedAt() {
      return this.timeFormatted(this.todo.createdAt);
    },
    formattedDueDate() {
      if (!this.dueDate) {
        return null;
      }

      if (isToday(this.dueDate)) {
        return s__('Todos|Due today');
      }

      return sprintf(s__('Todos|Due %{when}'), {
        when: formatDate(this.todo.targetEntity.dueDate, 'mmm dd, yyyy'),
      });
    },
    showDueDateAsError() {
      return this.dueDate && isInPast(this.dueDate);
    },
    showDueDateAsWarning() {
      return this.dueDate && isToday(this.dueDate);
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-gap-2 gl-text-sm gl-text-subtle sm:gl-h-7 sm:gl-flex-col sm:gl-justify-center sm:gl-gap-0"
  >
    <span class="gl-text-right">
      <todo-snoozed-timestamp
        v-if="todo.snoozedUntil"
        class="gl-mr-2"
        :snoozed-until="todo.snoozedUntil"
        :has-reached-snooze-timestamp="!isSnoozed"
      />

      {{ formattedCreatedAt }}
    </span>
    <span v-if="formattedDueDate" class="gl-inline sm:gl-hidden"> &middot; </span>
    <span
      v-if="formattedDueDate"
      :class="{
        'gl-text-danger': showDueDateAsError,
        'gl-text-warning': showDueDateAsWarning,
      }"
      >{{ formattedDueDate }}
    </span>
  </div>
</template>
