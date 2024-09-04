<script>
import { GlDaterangePicker, GlFormInput } from '@gitlab/ui';
import { formattedTimeFromDate, addTimeToDate } from '../utils';

const DEFAULT_TIME = '00:00:00';

export default {
  components: {
    GlDaterangePicker,
    GlFormInput,
  },
  props: {
    startOpened: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultStartDate: {
      type: Date,
      required: false,
      default: null,
    },
    defaultEndDate: {
      type: Date,
      required: false,
      default: null,
    },
    defaultMaxDate: {
      type: Date,
      required: false,
      default: null,
    },
    defaultMinDate: {
      type: Date,
      required: false,
      default: null,
    },
    maxDateRange: {
      type: Number,
      required: false,
      default: null,
    },
    state: {
      type: Boolean,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      startDate: this.defaultStartDate,
      endDate: this.defaultEndDate,
      timeInputStart: this.defaultStartDate
        ? formattedTimeFromDate(this.defaultStartDate)
        : DEFAULT_TIME,
      timeInputEnd: this.defaultEndDate ? formattedTimeFromDate(this.defaultEndDate) : DEFAULT_TIME,
    };
  },
  methods: {
    onDateRangeChange({ startDate, endDate }) {
      this.startDate = addTimeToDate(this.timeInputStart, startDate);
      this.endDate = addTimeToDate(this.timeInputEnd, endDate);
      this.$emit('input', {
        startDate: this.startDate,
        endDate: this.endDate,
      });
    },
    onTimeInputBlur() {
      if (!this.startDate || !this.endDate) {
        return;
      }

      const oldStartDate = this.startDate;
      const oldEndDate = this.endDate;

      this.startDate = addTimeToDate(this.timeInputStart, this.startDate);
      this.endDate = addTimeToDate(this.timeInputEnd, this.endDate);

      // setting 'lazy' on the time input doesn't work as expected, so we are explicitly
      // checking here if the value changed on blur
      if (
        oldEndDate.getTime() !== this.endDate.getTime() ||
        oldStartDate.getTime() !== this.startDate.getTime()
      ) {
        this.$emit('input', {
          startDate: this.startDate,
          endDate: this.endDate,
        });
      }
    },
  },
  TIME_INPUT_CLASS:
    'gl-flex gl-items-center gl-justify-center !gl-py-2 gl-min-w-fit gl-w-15 !gl-h-7',
};
</script>

<template>
  <gl-daterange-picker
    width="lg"
    :start-opened="startOpened"
    :default-start-date="startDate"
    :default-end-date="endDate"
    :default-max-date="defaultMaxDate"
    :default-min-date="defaultMinDate"
    :max-date-range="maxDateRange"
    :same-day-selection="true"
    :start-picker-state="state"
    :end-picker-state="state"
    @input="onDateRangeChange"
  >
    <template #after-start>
      <gl-form-input
        v-model="timeInputStart"
        :class="$options.TIME_INPUT_CLASS"
        type="time"
        step="10"
        :state="state"
        @blur="onTimeInputBlur"
      />
    </template>
    <template #after-end>
      <gl-form-input
        v-model="timeInputEnd"
        :class="$options.TIME_INPUT_CLASS"
        type="time"
        step="10"
        :state="state"
        @blur="onTimeInputBlur"
      />
    </template>
  </gl-daterange-picker>
</template>
