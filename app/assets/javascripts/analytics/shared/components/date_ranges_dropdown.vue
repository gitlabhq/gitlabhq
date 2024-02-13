<script>
import { GlCollapsibleListbox, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import { isString } from 'lodash';
import { isValidDate, getDayDifference } from '~/lib/utils/datetime_utility';
import {
  DATE_RANGE_CUSTOM_VALUE,
  DEFAULT_DATE_RANGE_OPTIONS,
  NUMBER_OF_DAYS_SELECTED,
} from '~/analytics/shared/constants';
import { __ } from '~/locale';

export default {
  name: 'DateRangesDropdown',
  components: {
    GlCollapsibleListbox,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    dateRangeOptions: {
      type: Array,
      required: false,
      default: () => DEFAULT_DATE_RANGE_OPTIONS,
      validator: (options) =>
        options.length &&
        options.every(
          ({ text, value, startDate, endDate }) =>
            isString(text) &&
            isString(value) &&
            isValidDate(startDate) &&
            isValidDate(endDate) &&
            endDate >= startDate,
        ),
    },
    selected: {
      type: String,
      required: false,
      default: '',
    },
    tooltip: {
      type: String,
      required: false,
      default: '',
    },
    includeCustomDateRangeOption: {
      type: Boolean,
      required: false,
      default: true,
    },
    includeEndDateInDaysSelected: {
      type: Boolean,
      required: false,
      default: false,
    },
    disableSelectedDayCount: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedValue: this.selected || this.dateRangeOptions[0].value,
    };
  },
  computed: {
    items() {
      const dateRangeOptions = this.dateRangeOptions.map(({ text, value }) => ({ text, value }));

      if (!this.includeCustomDateRangeOption) return dateRangeOptions;

      return [...dateRangeOptions, this.$options.customDateRangeItem];
    },
    isCustomDateRangeSelected() {
      return this.selectedValue === DATE_RANGE_CUSTOM_VALUE;
    },
    groupedDateRangeOptionsByValue() {
      return this.dateRangeOptions.reduce((acc, { value, startDate, endDate }) => {
        acc[value] = { startDate, endDate };

        return acc;
      }, {});
    },
    selectedDateRange() {
      if (this.isCustomDateRangeSelected) return null;

      return this.groupedDateRangeOptionsByValue[this.selectedValue];
    },
    showDaysSelectedCount() {
      return (
        !this.disableSelectedDayCount && !this.isCustomDateRangeSelected && this.daysSelectedCount
      );
    },
    daysSelectedCount() {
      const { selectedDateRange } = this;

      if (!selectedDateRange) return '';

      const { startDate, endDate } = selectedDateRange;

      const daysCount = getDayDifference(startDate, endDate);

      return this.$options.i18n.daysSelected(
        this.includeEndDateInDaysSelected ? daysCount + 1 : daysCount,
      );
    },
  },
  methods: {
    onSelect(value) {
      if (this.isCustomDateRangeSelected) {
        this.$emit('customDateRangeSelected');
      } else {
        this.$emit('selected', { value, ...this.selectedDateRange });
      }
    },
  },
  customDateRangeItem: {
    text: __('Custom'),
    value: DATE_RANGE_CUSTOM_VALUE,
  },
  i18n: {
    daysSelected: NUMBER_OF_DAYS_SELECTED,
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <gl-collapsible-listbox v-model="selectedValue" :items="items" @select="onSelect" />
    <div v-if="showDaysSelectedCount" class="gl-text-gray-500">
      <span data-testid="predefined-date-range-days-count">{{ daysSelectedCount }}</span>
      <gl-icon v-if="tooltip" v-gl-tooltip class="gl-ml-2" name="information-o" :title="tooltip" />
    </div>
  </div>
</template>
