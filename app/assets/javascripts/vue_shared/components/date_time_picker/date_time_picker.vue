<script>
import { GlIcon, GlButton, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

import { convertToFixedRange, isEqualTimeRanges, findTimeRange } from '~/lib/utils/datetime_range';

import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import DateTimePickerInput from './date_time_picker_input.vue';
import {
  defaultTimeRanges,
  defaultTimeRange,
  isValidInputString,
  inputStringToIsoDate,
  isoDateToInputString,
} from './date_time_picker_lib';

const events = {
  input: 'input',
  invalid: 'invalid',
};

export default {
  components: {
    GlIcon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    TooltipOnTruncate,
    DateTimePickerInput,
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: () => defaultTimeRange,
    },
    options: {
      type: Array,
      required: false,
      default: () => defaultTimeRanges,
    },
    customEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    utc: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      timeRange: this.value,

      /**
       * Valid start iso date string, null if not valid value
       */
      startDate: null,
      /**
       * Invalid start date string as input by the user
       */
      startFallbackVal: '',

      /**
       * Valid end iso date string, null if not valid value
       */
      endDate: null,
      /**
       * Invalid end date string as input by the user
       */
      endFallbackVal: '',
    };
  },
  computed: {
    startInputValid() {
      return isValidInputString(this.startDate);
    },
    endInputValid() {
      return isValidInputString(this.endDate);
    },
    isValid() {
      return this.startInputValid && this.endInputValid;
    },

    startInput: {
      get() {
        return this.dateToInput(this.startDate) || this.startFallbackVal;
      },
      set(val) {
        try {
          this.startDate = this.inputToDate(val);
          this.startFallbackVal = null;
        } catch (e) {
          this.startDate = null;
          this.startFallbackVal = val;
        }
        this.timeRange = null;
      },
    },
    endInput: {
      get() {
        return this.dateToInput(this.endDate) || this.endFallbackVal;
      },
      set(val) {
        try {
          this.endDate = this.inputToDate(val);
          this.endFallbackVal = null;
        } catch (e) {
          this.endDate = null;
          this.endFallbackVal = val;
        }
        this.timeRange = null;
      },
    },

    timeWindowText() {
      try {
        const timeRange = findTimeRange(this.value, this.options);
        if (timeRange) {
          return timeRange.label;
        }

        const { start, end } = convertToFixedRange(this.value);
        if (isValidInputString(start) && isValidInputString(end)) {
          return sprintf(__('%{start} to %{end}'), {
            start: this.stripZerosInDateTime(this.dateToInput(start)),
            end: this.stripZerosInDateTime(this.dateToInput(end)),
          });
        }
      } catch {
        return __('Invalid date range');
      }
      return '';
    },

    customLabel() {
      if (this.utc) {
        return __('Custom range (UTC)');
      }
      return __('Custom range');
    },
  },
  watch: {
    value(newValue) {
      const { start, end } = convertToFixedRange(newValue);
      this.timeRange = this.value;
      this.startDate = start;
      this.endDate = end;
    },
  },
  mounted() {
    try {
      const { start, end } = convertToFixedRange(this.timeRange);
      this.startDate = start;
      this.endDate = end;
    } catch {
      // when dates cannot be parsed, emit error.
      this.$emit(events.invalid);
    }

    // Validate on mounted, and trigger an update if needed
    if (!this.isValid) {
      this.$emit(events.invalid);
    }
  },
  methods: {
    dateToInput(date) {
      if (date === null) {
        return null;
      }
      return isoDateToInputString(date, this.utc);
    },
    inputToDate(value) {
      return inputStringToIsoDate(value, this.utc);
    },
    stripZerosInDateTime(str = '') {
      return str.replace(' 00:00:00', '');
    },
    closeDropdown() {
      this.$refs.dropdown.hide();
    },
    isOptionActive(option) {
      return isEqualTimeRanges(option, this.timeRange);
    },
    setQuickRange(option) {
      this.timeRange = option;
      this.$emit(events.input, this.timeRange);
    },
    setFixedRange() {
      this.timeRange = convertToFixedRange({
        start: this.startDate,
        end: this.endDate,
      });
      this.$emit(events.input, this.timeRange);
    },
  },
};
</script>
<template>
  <tooltip-on-truncate
    :title="timeWindowText"
    :truncate-target="elem => elem.querySelector('.gl-dropdown-toggle-text')"
    placement="top"
    class="d-inline-block"
  >
    <gl-dropdown
      ref="dropdown"
      :text="timeWindowText"
      v-bind="$attrs"
      class="date-time-picker w-100"
      menu-class="date-time-picker-menu"
      toggle-class="date-time-picker-toggle text-truncate"
    >
      <template #button-content>
        <span class="gl-flex-grow-1 text-truncate">{{ timeWindowText }}</span>
        <span v-if="utc" class="gl-text-gray-500 gl-font-weight-bold gl-font-sm">{{
          __('UTC')
        }}</span>
        <gl-icon class="gl-dropdown-caret" name="chevron-down" />
      </template>

      <div class="d-flex justify-content-between gl-p-2">
        <gl-form-group
          v-if="customEnabled"
          :label="customLabel"
          label-for="custom-from-time"
          label-class="gl-pb-2"
          class="custom-time-range-form-group col-md-7 gl-pl-2 gl-pr-0 m-0"
        >
          <div class="gl-pt-3">
            <date-time-picker-input
              id="custom-time-from"
              v-model="startInput"
              :label="__('From')"
              :state="startInputValid"
            />
            <date-time-picker-input
              id="custom-time-to"
              v-model="endInput"
              :label="__('To')"
              :state="endInputValid"
            />
          </div>
          <gl-form-group>
            <gl-button data-testid="cancelButton" @click="closeDropdown">{{
              __('Cancel')
            }}</gl-button>
            <gl-button
              variant="success"
              category="primary"
              :disabled="!isValid"
              @click="setFixedRange()"
            >
              {{ __('Apply') }}
            </gl-button>
          </gl-form-group>
        </gl-form-group>
        <gl-form-group label-for="group-id-dropdown" class="col-md-5 gl-px-2 m-0">
          <template #label>
            <span class="gl-pl-7">{{ __('Quick range') }}</span>
          </template>

          <gl-dropdown-item
            v-for="(option, index) in options"
            :key="index"
            data-qa-selector="quick_range_item"
            :active="isOptionActive(option)"
            active-class="active"
            @click="setQuickRange(option)"
          >
            <gl-icon
              name="mobile-issue-close"
              class="align-bottom"
              :class="{ invisible: !isOptionActive(option) }"
            />
            {{ option.label }}
          </gl-dropdown-item>
        </gl-form-group>
      </div>
    </gl-dropdown>
  </tooltip-on-truncate>
</template>
