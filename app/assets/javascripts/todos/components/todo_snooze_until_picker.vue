<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, sprintf } from '~/locale';
import dateFormat from '~/lib/dateformat';
import { nHoursAfter } from '~/lib/utils/datetime_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK } from '~/todos/constants';
import SnoozeTodoModal from './snooze_todo_modal.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlTooltip,
    SnoozeTodoModal,
  },
  mixins: [Tracking.mixin()],
  inject: ['currentTime'],
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

      const dayOfWeek = this.currentTime.getDay();
      const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek;
      const untilNextWeek = new Date(this.currentTime);
      untilNextWeek.setDate(this.currentTime.getDate() + daysUntilMonday);
      untilNextWeek.setHours(8, 0, 0, 0);

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
                this.$emit('snooze-until', forAnHour);
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
                this.$emit('snooze-until', untilLaterToday);
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

                this.$emit('snooze-until', untilTomorrow);
              },
            },
            {
              text: s__('Todos|Until next week'),
              formattedDate: sprintf(s__('Todos|%{day}, %{time}'), {
                day: dateFormat(untilNextWeek, 'DDDD'),
                time: toTimeString(untilNextWeek),
              }),
              action: () => {
                this.track(INSTRUMENT_TODO_ITEM_CLICK, {
                  label: 'snooze_until_next_week',
                });

                this.$emit('snooze-until', untilNextWeek);
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
  i18n: {
    snooze: s__('Todos|Snooze...'),
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
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
    <snooze-todo-modal
      ref="custom-snooze-time-modal"
      @submit="(until) => $emit('snooze-until', until)"
    />
  </div>
</template>
