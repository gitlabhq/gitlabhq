<script>
import { GlIcon } from '@gitlab/ui';
import dateFormat from '~/lib/dateformat';
import {
  getDayDifference,
  getDueDateStatus,
  getTimeago,
  humanTimeframe,
  localeDateFormat,
  newDate,
  formatDateLongMonthDay,
} from '~/lib/utils/datetime_utility';
import { sprintf, __ } from '~/locale';
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
        return `${timeago.format(this.issueDueDateTime)} (${this.standardDateFormat})`;
      }

      return timeago.format(this.issueDueDateTime);
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
    dueDateStatus() {
      return getDueDateStatus(this.date, !this.closed);
    },
    issueDueDate() {
      return newDate(this.date);
    },
    issueDueDateTime() {
      const dueDateTime = newDate(this.issueDueDate);
      dueDateTime.setHours(23, 59, 59, 999);
      return dueDateTime;
    },
    timeDifference() {
      const today = new Date();
      return getDayDifference(today, this.issueDueDate);
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
  methods: {
    createAriaLabel() {
      let dueDateAccessibleLabel;

      if (this.timeDifference >= -1 && this.timeDifference < 7) {
        dueDateAccessibleLabel = this.body;
      } else {
        dueDateAccessibleLabel = formatDateLongMonthDay(this.issueDueDate);
      }

      return sprintf(__(`Due date: %{date}`), {
        date: dueDateAccessibleLabel,
      });
    },
  },
};
</script>

<template>
  <work-item-attribute
    anchor-id="board-card-due-date"
    wrapper-component="button"
    :wrapper-component-class="`${cssClass} board-card-info !gl-cursor-help gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset`"
    :aria-label="createAriaLabel()"
  >
    <template #icon>
      <gl-icon :variant="dueDateStatus.iconVariant" :name="dueDateStatus.iconName" />
    </template>
    <template #title>
      <time datetime="date" class="board-card-info-text gl-text-sm">{{ body }}</time>
    </template>
    <template #tooltip-text>
      <span class="gl-font-bold">{{ __('Due date') }}</span>
      <br />
      <span>{{ title }}</span>
      <div v-if="dueDateStatus.statusLabel">({{ dueDateStatus.statusLabel }})</div>
    </template>
  </work-item-attribute>
</template>
