<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDaterangePicker } from '@gitlab/ui';
import { MAX_DATE_RANGE_TEXT, NUMBER_OF_DAYS_SELECTED } from '~/analytics/shared/constants';

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
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit('change', { startDate, endDate });
      },
    },
    maxDateRangeTooltip() {
      return this.$options.i18n.maxDateRangeTooltip(this.maxDateRange);
    },
  },
  methods: {
    numberOfDays(daysSelected) {
      return this.$options.i18n.daysSelected(daysSelected);
    },
  },
  i18n: {
    maxDateRangeTooltip: MAX_DATE_RANGE_TEXT,
    daysSelected: NUMBER_OF_DAYS_SELECTED,
  },
};
</script>
<template>
  <div
    v-if="show"
    class="align-items-lg-center justify-content-lg-end gl-flex gl-flex-col md:gl-flex-row"
  >
    <gl-daterange-picker
      v-model="dateRange"
      class="gl-flex gl-flex-col gl-flex-wrap gl-justify-end !gl-gap-3 sm:gl-flex-row md:gl-flex-nowrap"
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
      width="xl"
      start-picker-class="js-daterange-picker-from gl-flex gl-flex-col md:gl-flex-row md:gl-items-center gl-grow"
      end-picker-class="js-daterange-picker-to gl-flex gl-flex-col md:gl-flex-row md:gl-items-center gl-grow"
      label-class="gl-mb-3 sm:gl-mb-0"
    >
      <template #default="{ daysSelected }">
        <div class="gl-text-right">
          {{ numberOfDays(daysSelected) }}
        </div>
      </template>
    </gl-daterange-picker>
  </div>
</template>
