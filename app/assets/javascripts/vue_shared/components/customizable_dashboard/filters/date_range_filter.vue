<script>
import { GlCollapsibleListbox, GlDaterangePicker, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';
import { dateRangeOptionToFilter, getDateRangeOption } from '../utils';
import { TODAY, DATE_RANGE_OPTIONS, DEFAULT_SELECTED_OPTION_INDEX } from './constants';

export default {
  name: 'DateRangeFilter',
  components: {
    GlCollapsibleListbox,
    GlDaterangePicker,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    defaultOption: {
      type: String,
      required: false,
      default: DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX].key,
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
    dateRangeLimit: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      selectedItem: getDateRangeOption(this.defaultOption),
    };
  },
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit(
          'change',
          dateRangeOptionToFilter({
            ...this.selectedItem,
            startDate,
            endDate,
          }),
        );
      },
    },
    dateRangeTooltip() {
      if (this.dateRangeLimit) {
        return n__(
          'Date range limited to %d day',
          'Date range limited to %d days',
          this.dateRangeLimit,
        );
      }

      return null;
    },
    dropdownItems() {
      return this.$options.DATE_RANGE_OPTIONS.map((item) => {
        return { text: item.text, value: item.key };
      });
    },
  },
  methods: {
    selectItem(key) {
      const item = this.$options.DATE_RANGE_OPTIONS.find((option) => option.key === key);
      this.selectedItem = item;

      const { startDate, endDate, showDateRangePicker = false } = item;
      if (!showDateRangePicker && startDate && endDate) {
        this.dateRange = { startDate, endDate };
      }

      this.showDateRangePicker = showDateRangePicker;
    },
  },
  DATE_RANGE_OPTIONS,
  TODAY,
};
</script>

<template>
  <div
    class="gl-flex gl-w-full gl-gap-3 sm:gl-w-auto sm:gl-flex-row"
    :class="{ 'gl-flex-col': selectedItem.showDateRangePicker }"
  >
    <gl-collapsible-listbox
      class="gl-w-full sm:gl-w-auto"
      :items="dropdownItems"
      :selected="selectedItem.key"
      @select="selectItem($event)"
    />
    <div class="gl-flex gl-gap-3">
      <gl-daterange-picker
        v-if="selectedItem.showDateRangePicker"
        v-model="dateRange"
        :default-start-date="dateRange.startDate"
        :default-end-date="dateRange.endDate"
        :default-max-date="$options.TODAY"
        :max-date-range="dateRangeLimit"
        :to-label="__('To')"
        :from-label="__('From')"
        :tooltip="dateRangeTooltip"
        same-day-selection
      />
      <gl-icon
        v-gl-tooltip
        :title="s__('Analytics|Dates and times are displayed in the UTC timezone')"
        name="information-o"
        class="gl-mb-3 gl-min-w-5 gl-self-end"
        variant="subtle"
      />
    </div>
  </div>
</template>
