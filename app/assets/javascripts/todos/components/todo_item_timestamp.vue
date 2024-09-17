<script>
import { isInPast, isToday, newDateAsLocaleTime } from '~/lib/utils/datetime_utility';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { s__, sprintf } from '~/locale';

export default {
  mixins: [timeagoMixin],
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
    formattedCreatedAt() {
      return this.timeFormatted(this.todo.createdAt);
    },
    formattedDueDate() {
      if (!this.todo?.target.dueDate) {
        return null;
      }

      if (isToday(newDateAsLocaleTime(this.todo.target.dueDate))) {
        return s__('Todos|Due today');
      }

      return sprintf(s__('Todos|Due %{when}'), {
        when: formatDate(this.todo.target.dueDate, 'mmm dd, yyyy'),
      });
    },
    showDueDateAsError() {
      return this.todo.target.dueDate && isInPast(newDateAsLocaleTime(this.todo.target.dueDate));
    },
    showDueDateAsWarning() {
      return this.todo.target.dueDate && isToday(newDateAsLocaleTime(this.todo.target.dueDate));
    },
  },
};
</script>

<template>
  <span class="gl-text-sm gl-text-subtle">
    <span
      v-if="formattedDueDate"
      :class="{
        'gl-text-red-500': showDueDateAsError,
        'gl-text-orange-500': showDueDateAsWarning,
      }"
      >{{ formattedDueDate }}</span
    >
    <template v-if="todo.target.dueDate"> &middot; </template>
    {{ formattedCreatedAt }}
  </span>
</template>
