<script>
import dateFormat from 'dateformat';
import tooltip from '~/vue_shared/directives/tooltip';
import { sprintf, __ } from '~/locale';
import { getDayDifference, getTimeago } from '~/lib/utils/datetime_utility';

export default {
  directives: {
    tooltip,
  },
  props: {
    date: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      const timeago = getTimeago();
      const { timeDifference } = this;
      const formatedDate = dateFormat(this.issueDueDate, 'mmm d, yyyy', true);
      let title = timeago.format(this.issueDueDate);

      if (timeDifference === 0) {
        title = formatedDate;
      } else if (timeDifference < 0 || timeDifference < 7) {
        title = `${title} (${formatedDate})`;
      }

      return `<strong>${__('Due Date')}</strong> <br> <span class="${this.cssClass}">${sprintf(
        __('%{title}'),
        { title },
      )}<span>`;
    },
    body() {
      const { timeDifference, issueDueDate } = this;
      const currentYear = new Date().getFullYear();

      if (timeDifference === 0) return __('Today');
      if (timeDifference === -1) return __('Yesterday');
      if (timeDifference > 0 && timeDifference < 7) {
        return dateFormat(this.issueDueDate, 'dddd', true);
      }
      // If due date is in the current year, don’t show the year.
      const format = currentYear === issueDueDate.getFullYear() ? 'mmm d' : 'mmm d, yyyy';
      return dateFormat(issueDueDate, format, true);
    },
    issueDueDate() {
      return new Date(this.date);
    },
    timeDifference() {
      const today = new Date();
      return getDayDifference(today, this.issueDueDate);
    },
    cssClass() {
      if (this.timeDifference < 0) return 'text-danger';
      return '';
    },
  },
};
</script>

<template>
  <time
    v-tooltip
    :class="cssClass"
    :title="title"
    :datetime="date"
    data-html="true"
    data-placement="bottom"
    data-container="body"
    v-text="body">
  </time>
</template>
