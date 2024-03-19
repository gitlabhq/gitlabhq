<script>
import {
  GlIcon,
  GlDaterangePicker,
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlOutsideDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';

const CUSTOM_DATE_FILTER_TYPE = 'custom-date';

export default {
  directives: { Outside: GlOutsideDirective },
  components: {
    GlIcon,
    GlDaterangePicker,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      datePickerShown: false,
    };
  },
  computed: {
    isActive() {
      return this.datePickerShown || this.active;
    },
    computedValue() {
      if (this.datePickerShown) {
        return {
          ...this.value,
          data: '',
        };
      }
      return this.value;
    },
    dataSegmentInputAttributes() {
      const id = 'time_range_data_segment_input';
      if (this.datePickerShown) {
        return {
          id,
          placeholder: 'YYYY-MM-DD - YYYY-MM-DD', // eslint-disable-line @gitlab/require-i18n-strings
          style: 'padding-left: 23px;',
        };
      }
      return {
        id,
      };
    },
    computedConfig() {
      return {
        ...this.config,
        options: undefined, // remove options from config to avoid default options being rendered
      };
    },
    suggestions() {
      const suggestions = this.config.options.map((option) => ({
        value: option.value,
        text: option.title,
      }));
      suggestions.push({ value: CUSTOM_DATE_FILTER_TYPE, text: __('Custom') });
      return suggestions;
    },
    defaultStartDate() {
      return new Date();
    },
  },
  methods: {
    hideDatePicker() {
      this.datePickerShown = false;
    },
    showDatePicker() {
      this.datePickerShown = true;
    },
    handleClickOutside() {
      this.hideDatePicker();
    },
    handleComplete(value) {
      if (value === CUSTOM_DATE_FILTER_TYPE) {
        this.showDatePicker();
      }
    },
    selectValue(inputValue, submitValue) {
      let value = inputValue;
      if (typeof inputValue === 'object' && inputValue.startDate && inputValue.endDate) {
        const { startDate, endDate } = inputValue;
        const format = 'yyyy-mm-dd';
        value = `${formatDate(startDate, format)} - ${formatDate(endDate, format)}`;
      }
      submitValue(value);
      this.hideDatePicker();
    },
  },
  CUSTOM_DATE_FILTER_TYPE: 'custom-date',
};
</script>

<template>
  <gl-filtered-search-token
    :data-segment-input-attributes="dataSegmentInputAttributes"
    v-bind="{ ...$props, ...$attrs }"
    :view-only="datePickerShown"
    :active="isActive"
    :value="computedValue"
    :config="computedConfig"
    v-on="$listeners"
    @complete="handleComplete"
  >
    <template #before-data-segment-input="{ submitValue }">
      <gl-icon
        v-if="datePickerShown"
        class="gl-text-gray-500"
        name="calendar"
        style="margin-left: 5px; margin-right: -15px; z-index: 1; pointer-events: none"
      />
      <div
        v-if="datePickerShown"
        v-outside="handleClickOutside"
        class="gl-absolute gl-z-index-1 gl-bg-white gl-border-1 gl-border-gray-200 gl-my-2 gl-p-4 gl-rounded-base gl-shadow-x0-y2-b4-s0 gl-top-full"
      >
        <gl-daterange-picker
          :max-date-range="computedConfig.maxDateRange"
          start-opened
          :default-start-date="defaultStartDate"
          :default-max-date="defaultStartDate"
          @input="selectValue($event, submitValue)"
        />
      </div>
    </template>

    <template #suggestions>
      <div v-if="!datePickerShown">
        <gl-filtered-search-suggestion
          v-for="token in suggestions"
          :key="token.value"
          :value="token.value"
        >
          {{ token.text }}
        </gl-filtered-search-suggestion>
      </div>
    </template>
  </gl-filtered-search-token>
</template>
