<script>
import { periodToDate } from '~/observability/utils';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import { TIME_RANGE_OPTIONS, CUSTOM_DATE_RANGE_OPTION } from '~/observability/constants';
import { dayAfter, getCurrentUtcDate } from '~/lib/utils/datetime_utility';
import DateTimeRangePicker from './datetime_range_picker.vue';

export default {
  components: {
    DateRangesDropdown,
    DateTimeRangePicker,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: null,
    },
    maxDateRange: {
      type: Number,
      required: false,
      default: null,
    },
    dateOptions: {
      type: Array,
      required: false,
      default: () => TIME_RANGE_OPTIONS,
    },
    defaultMinDate: {
      type: Date,
      required: false,
      default: null,
    },
    dateTimeRangePickerState: {
      type: Boolean,
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
      return this.dateOptions.map((option) => {
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
    defaultMaxDate() {
      return dayAfter(getCurrentUtcDate(), { utc: true });
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
  <div class="gl-flex gl-flex-col gl-gap-3 lg:gl-flex-row" data-testid="date-range-filter">
    <date-ranges-dropdown
      :selected="dateRange.value"
      :date-range-options="dateRangeOptions"
      disable-date-range-string
      @selected="onSelectPredefinedDateRange"
      @customDateRangeSelected="onSelectCustomDateRange"
    />
    <date-time-range-picker
      v-if="shouldShowDateRangePicker"
      :start-opened="shouldStartOpened"
      :default-start-date="dateRange.startDate"
      :default-end-date="dateRange.endDate"
      :max-date-range="maxDateRange"
      :default-max-date="defaultMaxDate"
      :default-min-date="defaultMinDate"
      :state="dateTimeRangePickerState"
      @input="onCustomRangeSelected"
    />
  </div>
</template>
