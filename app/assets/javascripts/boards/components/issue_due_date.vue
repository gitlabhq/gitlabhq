<script>
import { GlIcon } from '@gitlab/ui';
import dateFormat from '~/lib/dateformat';
import {
  getDayDifference,
  getTimeago,
  humanTimeframe,
  localeDateFormat,
  newDate,
} from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  components: {
    WorkItemAttribute,
    GlIcon,
  },
  props: {
    closed: {
      type: Boolean,
      required: false,
      default: false,
    },
    date: {
      type: String,
      required: true,
    },
    startDate: {
      type: String,
      required: false,
      default: undefined,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    title() {
      const timeago = getTimeago();

      if (this.timeDifference >= -1 && this.timeDifference < 7) {
        return `${timeago.format(this.issueDueDate)} (${this.standardDateFormat})`;
      }

      return timeago.format(this.issueDueDate);
    },
    body() {
      if (this.timeDifference === 0) {
        return __('Today');
      }
      if (this.timeDifference === 1) {
        return __('Tomorrow');
      }
      if (this.timeDifference === -1) {
        return __('Yesterday');
      }
      if (this.timeDifference > 0 && this.timeDifference < 7) {
        return dateFormat(this.issueDueDate, 'dddd');
      }

      return this.standardDateFormat;
    },
    iconName() {
      return this.isOverdue ? 'calendar-overdue' : 'calendar';
    },
    issueDueDate() {
      return newDate(this.date);
    },
    timeDifference() {
      const today = new Date();
      return getDayDifference(today, this.issueDueDate);
    },
    isOverdue() {
      return !this.closed && this.timeDifference < 0;
    },
    standardDateFormat() {
      if (this.startDate) {
        return humanTimeframe(newDate(this.startDate), this.issueDueDate);
      }

      const today = new Date();
      return today.getFullYear() === this.issueDueDate.getFullYear()
        ? localeDateFormat.asDateWithoutYear.format(this.issueDueDate)
        : localeDateFormat.asDate.format(this.issueDueDate);
    },
  },
};
</script>

<template>
  <work-item-attribute
    anchor-id="board-card-due-date"
    wrapper-component="button"
    :wrapper-component-class="`${cssClass} board-card-info gl-mr-3 !gl-cursor-help gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset`"
  >
    <template #icon>
      <gl-icon
        :variant="isOverdue ? 'danger' : 'subtle'"
        class="board-card-info-icon"
        :name="iconName"
      />
    </template>
    <template #title>
      <time datetime="date" class="board-card-info-text gl-text-sm">{{ body }}</time>
    </template>
    <template #tooltip-text>
      <span class="gl-font-bold">{{ __('Due date') }}</span>
      <br />
      <span>{{ title }}</span>
      <div v-if="isOverdue">({{ __('overdue') }})</div>
    </template>
  </work-item-attribute>
</template>
