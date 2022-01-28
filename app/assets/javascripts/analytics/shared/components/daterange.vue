<script>
import { GlDaterangePicker, GlSprintf } from '@gitlab/ui';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import { OFFSET_DATE_BY_ONE } from '../constants';

export default {
  components: {
    GlDaterangePicker,
    GlSprintf,
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
          'Showing data for workflow items created in this date range. Date range limited to %{maxDateRange} days.',
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
    numberOfDays() {
      const dayDifference = getDayDifference(this.startDate, this.endDate);
      return this.includeSelectedDate ? dayDifference + OFFSET_DATE_BY_ONE : dayDifference;
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
      class="d-flex flex-column flex-lg-row"
      :default-start-date="startDate"
      :default-end-date="endDate"
      :default-min-date="minDate"
      :max-date-range="maxDateRange"
      :default-max-date="maxDate"
      :same-day-selection="includeSelectedDate"
      :tooltip="maxDateRangeTooltip"
      theme="animate-picker"
      start-picker-class="js-daterange-picker-from gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-lg-align-items-center gl-lg-mr-3 gl-mb-2 gl-lg-mb-0"
      end-picker-class="js-daterange-picker-to d-flex flex-column flex-lg-row align-items-lg-center gl-mb-2 gl-lg-mb-0"
      label-class="gl-mb-2 gl-lg-mb-0"
    >
      <gl-sprintf :message="n__('1 day selected', '%d days selected', numberOfDays)">
        <template #numberOfDays>{{ numberOfDays }}</template>
      </gl-sprintf>
    </gl-daterange-picker>
  </div>
</template>
