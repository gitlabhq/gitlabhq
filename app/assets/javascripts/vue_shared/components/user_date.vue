<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { SHORT_DATE_FORMAT, DATE_FORMATS } from '../constants';

export default {
  props: {
    date: {
      type: String,
      required: false,
      default: null,
    },
    dateFormat: {
      type: String,
      required: false,
      default: SHORT_DATE_FORMAT,
      validator: (dateFormat) => DATE_FORMATS.includes(dateFormat),
    },
  },
  computed: {
    formattedDate() {
      const { date } = this;
      if (date === null) {
        return __('Never');
      }

      let dateWithTime = new Date(date);

      // Set local midnight on dates passed as YYYY-MM-DD
      if (date.match(/^\d{4,}-\d{2}-\d{2}$/)) {
        dateWithTime = new Date(`${date}T00:00`);
      }

      return formatDate(dateWithTime, this.dateFormat);
    },
  },
};
</script>
<template>
  <span>
    {{ formattedDate }}
  </span>
</template>
