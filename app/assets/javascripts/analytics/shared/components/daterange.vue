<script>
import { GlDaterangePicker } from '@gitlab/ui';
import { n__, __, sprintf } from '~/locale';

export default {
  components: {
    GlDaterangePicker,
  },
  props: {
    show: {
      type: Boolean,
      required: false,
      default: true,
    },
    startDate: {
      type: Date,
      required: false,
      default: null,
    },
    endDate: {
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
      default() {
        return new Date();
      },
    },
    maxDateRange: {
      type: Number,
      required: false,
      default: 0,
    },
    includeSelectedDate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      maxDateRangeTooltip: sprintf(
        __(
          'Showing data for workflow items completed in this date range. Date range limited to %{maxDateRange} days.',
        ),
        {
          maxDateRange: this.maxDateRange,
        },
      ),
    };
  },
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit('change', { startDate, endDate });
      },
    },
  },
  methods: {
    numberOfDays(daysSelected) {
      return n__('1 day selected', '%d days selected', daysSelected);
    },
  },
};
</script>
<template>
  <div
    v-if="show"
    class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row align-items-lg-center justify-content-lg-end"
  >
    <gl-daterange-picker
      v-model="dateRange"
      class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row"
      :default-start-date="startDate"
      :default-end-date="endDate"
      :default-min-date="minDate"
      :max-date-range="maxDateRange"
      :default-max-date="maxDate"
      :same-day-selection="includeSelectedDate"
      :tooltip="maxDateRangeTooltip"
      :from-label="__('From')"
      :to-label="__('To')"
      theme="animate-picker"
      start-picker-class="js-daterange-picker-from gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-lg-align-items-center gl-lg-mr-3 gl-mb-2 gl-lg-mb-0"
      end-picker-class="js-daterange-picker-to gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-lg-align-items-center gl-mb-2 gl-lg-mb-0"
      label-class="gl-mb-2 gl-lg-mb-0"
    >
      <template #default="{ daysSelected }">
        {{ numberOfDays(daysSelected) }}
      </template>
    </gl-daterange-picker>
  </div>
</template>
