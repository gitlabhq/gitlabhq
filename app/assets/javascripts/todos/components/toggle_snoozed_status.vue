<script>
import { GlButton, GlDisclosureDropdown, GlDisclosureDropdownGroup, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { s__, sprintf } from '~/locale';
import { nHoursAfter } from '~/lib/utils/datetime_utility';
import { reportToSentry } from '~/ci/utils';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK } from '~/todos/constants';
import { snoozeTodo } from '../utils';
import unSnoozeTodoMutation from './mutations/un_snooze_todo.mutation.graphql';
import SnoozeTodoModal from './snooze_todo_modal.vue';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlTooltip,
    SnoozeTodoModal,
  },
  mixins: [Tracking.mixin()],
  inject: ['currentTime'],
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
  data() {
    return {
      toggleId: uniqueId('snooze-todo-dropdown-toggle-btn-'),
      isOpen: false,
    };
  },
  computed: {
    showSnoozingDropdown() {
      return !this.isSnoozed && this.isPending;
    },
    dropdownOptions() {
      const forAnHour = nHoursAfter(this.currentTime, 1);
      const untilLaterToday = nHoursAfter(this.currentTime, 4);
      const untilTomorrow = new Date(
        this.currentTime.getFullYear(),
        this.currentTime.getMonth(),
        this.currentTime.getDate() + 1,
        8,
      );

      const toTimeString = (date) => localeDateFormat.asTime.format(date);

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
              action: () => {
                this.track(INSTRUMENT_TODO_ITEM_CLICK, {
                  label: 'snooze_for_one_hour',
                });
                this.snooze(forAnHour);
              },
            },
            {
              text: s__('Todos|Until later today'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(untilLaterToday, 'DDDD'),
                time: toTimeString(untilLaterToday),
              }),
              action: () => {
                this.track(INSTRUMENT_TODO_ITEM_CLICK, {
                  label: 'snooze_until_later_today',
                });
                this.snooze(untilLaterToday);
              },
            },
            {
              text: s__('Todos|Until tomorrow'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(untilTomorrow, 'DDDD'),
                time: toTimeString(untilTomorrow),
              }),
              action: () => {
                this.track(INSTRUMENT_TODO_ITEM_CLICK, {
                  label: 'snooze_until_tomorrow',
                });

                this.snooze(untilTomorrow);
              },
            },
          ],
        },
        {
          items: [
            {
              text: s__('Todos|Until a specific time and date'),
              action: () => {
                this.$refs['custom-snooze-time-modal'].show();
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
    snooze: s__('Todos|Snooze...'),
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
    <gl-disclosure-dropdown
      v-else-if="showSnoozingDropdown"
      :toggle-id="toggleId"
      :items="dropdownOptions"
      :toggle-text="$options.i18n.snooze"
      data-testid="snooze-dropdown"
      icon="clock"
      placement="bottom-end"
      text-sr-only
      no-caret
      fluid-width
      @shown="isOpen = true"
      @hidden="isOpen = false"
    >
      <gl-disclosure-dropdown-group :group="dropdownOptions[0]">
        <template #list-item="{ item }">
          <div class="gl-flex gl-justify-between gl-gap-5 gl-whitespace-nowrap">
            <div>
              {{ item.text }}
            </div>
            <div class="gl-text-right gl-text-secondary">{{ item.formattedDate }}</div>
          </div>
        </template>
      </gl-disclosure-dropdown-group>
      <gl-disclosure-dropdown-group bordered border-position="top" :group="dropdownOptions[1]" />
    </gl-disclosure-dropdown>
    <gl-tooltip v-if="!isOpen" :target="toggleId">
      {{ $options.i18n.snooze }}
    </gl-tooltip>
    <snooze-todo-modal ref="custom-snooze-time-modal" :todo="todo" />
  </span>
</template>
