<script>
import { GlDeprecatedButton, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

import { convertToFixedRange, isEqualTimeRanges, findTimeRange } from '~/lib/utils/datetime_range';

import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import DateTimePickerInput from './date_time_picker_input.vue';
import {
  defaultTimeRanges,
  defaultTimeRange,
  isValidDate,
  stringToISODate,
  ISODateToString,
  truncateZerosInDateTime,
  isDateTimePickerInputValid,
} from './date_time_picker_lib';

const events = {
  input: 'input',
  invalid: 'invalid',
};

export default {
  components: {
    Icon,
    TooltipOnTruncate,
    DateTimePickerInput,
    GlFormGroup,
    GlDeprecatedButton,
    GlDropdown,
    GlDropdownItem,
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
  },
  data() {
    return {
      timeRange: this.value,
      startDate: '',
      endDate: '',
    };
  },
  computed: {
    startInputValid() {
      return isValidDate(this.startDate);
    },
    endInputValid() {
      return isValidDate(this.endDate);
    },
    isValid() {
      return this.startInputValid && this.endInputValid;
    },

    startInput: {
      get() {
        return this.startInputValid ? this.formatDate(this.startDate) : this.startDate;
      },
      set(val) {
        // Attempt to set a formatted date if possible
        this.startDate = isDateTimePickerInputValid(val) ? stringToISODate(val) : val;
        this.timeRange = null;
      },
    },
    endInput: {
      get() {
        return this.endInputValid ? this.formatDate(this.endDate) : this.endDate;
      },
      set(val) {
        // Attempt to set a formatted date if possible
        this.endDate = isDateTimePickerInputValid(val) ? stringToISODate(val) : val;
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
        if (isValidDate(start) && isValidDate(end)) {
          return sprintf(__('%{start} to %{end}'), {
            start: this.formatDate(start),
            end: this.formatDate(end),
          });
        }
      } catch {
        return __('Invalid date range');
      }
      return '';
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
    formatDate(date) {
      return truncateZerosInDateTime(ISODateToString(date));
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
      :text="timeWindowText"
      v-bind="$attrs"
      class="date-time-picker w-100"
      menu-class="date-time-picker-menu"
      toggle-class="date-time-picker-toggle text-truncate"
    >
      <div class="d-flex justify-content-between gl-p-2">
        <gl-form-group
          v-if="customEnabled"
          :label="__('Custom range')"
          label-for="custom-from-time"
          label-class="gl-pb-1"
          class="custom-time-range-form-group col-md-7 gl-pl-1 gl-pr-0 m-0"
        >
          <div class="gl-pt-2">
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
            <gl-deprecated-button @click="closeDropdown">{{ __('Cancel') }}</gl-deprecated-button>
            <gl-deprecated-button variant="success" :disabled="!isValid" @click="setFixedRange()">
              {{ __('Apply') }}
            </gl-deprecated-button>
          </gl-form-group>
        </gl-form-group>
        <gl-form-group label-for="group-id-dropdown" class="col-md-5 gl-pl-1 gl-pr-1 m-0">
          <template #label>
            <span class="gl-pl-5">{{ __('Quick range') }}</span>
          </template>

          <gl-dropdown-item
            v-for="(option, index) in options"
            :key="index"
            :active="isOptionActive(option)"
            active-class="active"
            @click="setQuickRange(option)"
          >
            <icon
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
