<script>
import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { s__, sprintf } from '~/locale';
import { nHoursAfter } from '~/lib/utils/datetime_utility';
import { reportToSentry } from '~/ci/utils';
import snoozeTodoMutation from './mutations/snooze_todo.mutation.graphql';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
  },
  inject: ['currentTime'],
  props: {
    todo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      toggleId: uniqueId('snooze-todo-dropdown-toggle-btn-'),
      isOpen: false,
    };
  },
  computed: {
    dropdownOptions() {
      const forAnHour = nHoursAfter(this.currentTime, 1);
      const untilLaterToday = nHoursAfter(this.currentTime, 4);
      const untilTomorrow = new Date(
        this.currentTime.getFullYear(),
        this.currentTime.getMonth(),
        this.currentTime.getDate() + 1,
        8,
      );

      const toTimeString = (date) =>
        date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

      return [
        {
          name: s__('Todos|Snooze'),
          items: [
            {
              text: s__('Todos|For one hour'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(forAnHour, 'DDDD'),
                time: toTimeString(forAnHour),
              }),
              action: () => this.snooze(forAnHour),
            },
            {
              text: s__('Todos|Until later today'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(untilLaterToday, 'DDDD'),
                time: toTimeString(untilLaterToday),
              }),
              action: () => this.snooze(untilLaterToday),
            },
            {
              text: s__('Todos|Until tomorrow'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(untilTomorrow, 'DDDD'),
                time: toTimeString(untilTomorrow),
              }),
              action: () => {
                this.snooze(untilTomorrow);
              },
            },
          ],
        },
      ];
    },
  },
  methods: {
    async snooze(until) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: snoozeTodoMutation,
          variables: {
            todoId: this.todo.id,
            snoozeUntil: until,
          },
          optimisticResponse: {
            todoSnooze: {
              todo: {
                id: this.todo.id,
                snoozedUntil: until,
                __typename: 'Todo',
              },
              errors: [],
            },
          },
        });

        if (data.errors?.length) {
          throw new Error(data.errors.join(', '));
        }
      } catch (error) {
        reportToSentry(this.$options.name, error);
        this.showError();
      }
    },
    showError() {
      this.$toast.show(s__('Todos|Failed to snooze todo. Try again later.'), {
        variant: 'danger',
      });
    },
  },
  i18n: {
    snooze: s__('Todos|Snooze'),
  },
};
</script>

<template>
  <span>
    <gl-disclosure-dropdown
      :toggle-id="toggleId"
      :items="dropdownOptions"
      :toggle-text="$options.i18n.snooze"
      icon="clock"
      placement="bottom-end"
      text-sr-only
      no-caret
      fluid-width
      @shown="isOpen = true"
      @hidden="isOpen = false"
    >
      <template #list-item="{ item }">
        <div class="gl-flex gl-justify-between gl-gap-5 gl-whitespace-nowrap">
          <div>
            {{ item.text }}
          </div>
          <div class="gl-text-right gl-text-secondary">{{ item.formattedDate }}</div>
        </div>
      </template>
    </gl-disclosure-dropdown>
    <gl-tooltip v-if="!isOpen" :target="toggleId">
      {{ $options.i18n.snooze }}
    </gl-tooltip>
  </span>
</template>
