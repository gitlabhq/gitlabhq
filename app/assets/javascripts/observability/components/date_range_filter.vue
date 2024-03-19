<script>
import { GlDaterangePicker } from '@gitlab/ui';
import { periodToDate } from '~/observability/utils';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import { TIME_RANGE_OPTIONS, CUSTOM_DATE_RANGE_OPTION } from '~/observability/constants';

export default {
  components: {
    DateRangesDropdown,
    GlDaterangePicker,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      dateRange: this.selected ?? {
        value: '',
        startDate: null,
        endDate: null,
      },
    };
  },
  computed: {
    dateRangeOptions() {
      return TIME_RANGE_OPTIONS.map((option) => {
        const dateRange = periodToDate(option.value);
        return {
          value: option.value,
          text: option.title,
          startDate: dateRange.min,
          endDate: dateRange.max,
        };
      });
    },
    shouldShowDateRangePicker() {
      return this.dateRange.value === CUSTOM_DATE_RANGE_OPTION;
    },
    shouldStartOpened() {
      return (
        this.shouldShowDateRangePicker && (!this.dateRange.startDate || !this.dateRange.endDate)
      );
    },
  },
  methods: {
    onSelectPredefinedDateRange({ value, startDate, endDate }) {
      this.dateRange = {
        value,
        startDate: new Date(startDate),
        endDate: new Date(endDate),
      };
      this.$emit('onDateRangeSelected', this.dateRange);
    },
    onSelectCustomDateRange() {
      this.dateRange = {
        value: CUSTOM_DATE_RANGE_OPTION,
        startDate: undefined,
        endDate: undefined,
      };
    },
    onCustomRangeSelected({ startDate, endDate }) {
      this.dateRange = {
        value: CUSTOM_DATE_RANGE_OPTION,
        startDate: new Date(startDate),
        endDate: new Date(endDate),
      };
      this.$emit('onDateRangeSelected', this.dateRange);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-gap-3">
    <date-ranges-dropdown
      :selected="dateRange.value"
      :date-range-options="dateRangeOptions"
      disable-selected-day-count
      tooltip=""
      include-end-date-in-days-selected
      @selected="onSelectPredefinedDateRange"
      @customDateRangeSelected="onSelectCustomDateRange"
    />
    <gl-daterange-picker
      v-if="shouldShowDateRangePicker"
      :start-opened="shouldStartOpened"
      :default-start-date="dateRange.startDate"
      :default-end-date="dateRange.endDate"
      @input="onCustomRangeSelected"
    />
  </div>
</template>
