<script>
import dateFormat from 'dateformat';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import { sprintf, __ } from '~/locale';
import { getDayDifference, getTimeago } from '~/lib/utils/datetime_utility';

export default {
  components: {
    Icon,
  },
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
      const { timeDifference, standardDateFormat, cssClass } = this;
      const formatedDate = standardDateFormat;
      const className = cssClass ? `${cssClass}-muted` : '';
      let title = timeago.format(this.issueDueDate);

      if (timeDifference >= -1 && timeDifference < 7) {
        title = `${title} (${formatedDate})`;
      }

      return `<span class="bold">${__('Due date')}</span><br><span class="${className}">${sprintf(
        __('%{title}'),
        { title },
      )}<span>`;
    },
    body() {
      const { timeDifference, issueDueDate, standardDateFormat } = this;

      if (timeDifference === 0) return __('Today');
      if (timeDifference === 1) return __('Tomorrow');
      if (timeDifference === -1) return __('Yesterday');
      if (timeDifference > 0 && timeDifference < 7) return dateFormat(issueDueDate, 'dddd', true);
      return standardDateFormat;
    },
    issueDueDate() {
      return new Date(this.date);
    },
    timeDifference() {
      const today = new Date();
      return getDayDifference(today, this.issueDueDate);
    },
    cssClass() {
      if (this.timeDifference >= 0) return;
      return 'text-danger';
    },
    isDueInCurrentYear() {
      const today = new Date();
      return today.getFullYear() === this.issueDueDate.getFullYear();
    },
    standardDateFormat() {
      const yearformat = this.isDueInCurrentYear ? '' : ', yyyy';
      return dateFormat(this.issueDueDate, `mmm d${yearformat}`, true);
    },
  },
};
</script>

<template>
  <span
    v-tooltip
    :title="title"
    class="board-card-info card-number"
    data-html="true"
    data-placement="bottom"
    data-container="body"
  >
    <icon
      :css-classes="cssClass"
      name="calendar"
    /><time
      :class="cssClass"
      datetime="date"
      class="board-card-info-text">{{ body }}</time>
  </span>
</template>
