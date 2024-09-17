<script>
import { GlDatepicker, GlFormInput } from '@gitlab/ui';
import { dateToTimeInputValue, timeToHoursMinutes } from '~/lib/utils/datetime/date_format_utility';

export default {
  name: 'DatetimePicker',
  components: {
    GlDatepicker,
    GlFormInput,
  },
  props: {
    value: {
      type: Date,
      required: true,
    },
  },
  computed: {
    date: {
      get() {
        return this.value;
      },
      set(val) {
        const dup = new Date(this.value.getTime());
        dup.setFullYear(val.getFullYear(), val.getMonth(), val.getDate());
        this.$emit('input', dup);
      },
    },
    time: {
      get() {
        return dateToTimeInputValue(this.value);
      },
      set(val) {
        const dup = new Date(this.value.getTime());
        const { hours, minutes } = timeToHoursMinutes(val);
        dup.setHours(hours, minutes);
        this.$emit('input', dup);
      },
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <gl-datepicker v-model="date" />
    <gl-form-input v-model="time" width="sm" type="time" data-testid="time-picker" />
  </div>
</template>
