<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { SHORT_DATE_FORMAT } from '../constants';

export default {
  props: {
    date: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    formattedDate() {
      const { date } = this;
      if (date === null) {
        return __('Never');
      }
      return formatDate(new Date(date), SHORT_DATE_FORMAT);
    },
  },
};
</script>
<template>
  <span>
    {{ formattedDate }}
  </span>
</template>
