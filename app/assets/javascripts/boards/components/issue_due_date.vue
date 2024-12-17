<script>
import { GlIcon } from '@gitlab/ui';
import dateFormat from '~/lib/dateformat';
import {
  getDayDifference,
  getTimeago,
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
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'bottom',
    },
  },
  computed: {
    title() {
      const timeago = getTimeago();
      const { timeDifference, standardDateFormat } = this;
      const formattedDate = standardDateFormat;

      if (timeDifference >= -1 && timeDifference < 7) {
        return `${timeago.format(this.issueDueDate)} (${formattedDate})`;
      }

      return timeago.format(this.issueDueDate);
    },
    body() {
      const { timeDifference, issueDueDate, standardDateFormat } = this;

      if (timeDifference === 0) {
        return __('Today');
      }
      if (timeDifference === 1) {
        return __('Tomorrow');
      }
      if (timeDifference === -1) {
        return __('Yesterday');
      }
      if (timeDifference > 0 && timeDifference < 7) {
        return dateFormat(issueDueDate, 'dddd');
      }

      return standardDateFormat;
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
      if (this.timeDifference >= 0 || this.closed) return false;
      return true;
    },
    standardDateFormat() {
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
    wrapper-component="span"
    :wrapper-component-class="`${cssClass} board-card-info gl-mr-3 gl-cursor-help gl-text-subtle`"
  >
    <template #icon>
      <gl-icon
        :variant="isOverdue ? 'danger' : 'subtle'"
        class="board-card-info-icon gl-mr-2"
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
