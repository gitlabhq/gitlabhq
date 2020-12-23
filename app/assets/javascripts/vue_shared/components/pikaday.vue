<script>
import { GlDatepicker } from '@gitlab/ui';
import { pikadayToString } from '~/lib/utils/datetime_utility';

export default {
  name: 'DatePicker',
  components: {
    GlDatepicker,
  },
  props: {
    selectedDate: {
      type: Date,
      required: false,
      default: null,
    },
    minDate: {
      type: Date,
      required: false,
      default: null,
    },
    maxDate: {
      type: Date,
      required: false,
      default: null,
    },
  },
  methods: {
    selected(date) {
      this.$emit('newDateSelected', pikadayToString(date));
    },
    toggled() {
      this.$emit('hidePicker');
    },
  },
};
</script>

<template>
  <gl-datepicker
    :value="selectedDate"
    :min-date="minDate"
    :max-date="maxDate"
    start-opened
    @close="toggled"
    @click="toggled"
    @input="selected"
  />
</template>
