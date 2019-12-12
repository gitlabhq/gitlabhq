<script>
import dateFormat from 'dateformat';
import { GlTooltip } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import {
  getDayDifference,
  getTimeago,
  dateInWords,
  parsePikadayDate,
} from '~/lib/utils/datetime_utility';

export default {
  components: {
    Icon,
    GlTooltip,
  },
  props: {
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
      } else if (timeDifference === 1) {
        return __('Tomorrow');
      } else if (timeDifference === -1) {
        return __('Yesterday');
      } else if (timeDifference > 0 && timeDifference < 7) {
        return dateFormat(issueDueDate, 'dddd');
      }

      return standardDateFormat;
    },
    issueDueDate() {
      return parsePikadayDate(this.date);
    },
    timeDifference() {
      const today = new Date();
      return getDayDifference(today, this.issueDueDate);
    },
    isPastDue() {
      if (this.timeDifference >= 0) return false;
      return true;
    },
    standardDateFormat() {
      const today = new Date();
      const isDueInCurrentYear = today.getFullYear() === this.issueDueDate.getFullYear();

      return dateInWords(this.issueDueDate, true, isDueInCurrentYear);
    },
  },
};
</script>

<template>
  <span>
    <span ref="issueDueDate" :class="cssClass" class="board-card-info card-number">
      <icon
        :class="{ 'text-danger': isPastDue }"
        class="board-card-info-icon align-top"
        name="calendar"
      />
      <time :class="{ 'text-danger': isPastDue }" datetime="date" class="board-card-info-text">{{
        body
      }}</time>
    </span>
    <gl-tooltip :target="() => $refs.issueDueDate" :placement="tooltipPlacement">
      <span class="bold">{{ __('Due date') }}</span> <br />
      <span :class="{ 'text-danger-muted': isPastDue }">{{ title }}</span>
    </gl-tooltip>
  </span>
</template>
