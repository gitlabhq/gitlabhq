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
      return formatDate(new Date(date), this.dateFormat);
    },
  },
};
</script>
<template>
  <span>
    {{ formattedDate }}
  </span>
</template>
