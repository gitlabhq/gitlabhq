<script>
import { GlButton, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DateTimePickerInput from './date_time_picker_input.vue';
import {
  defaultTimeWindows,
  isValidDate,
  getTimeRange,
  getTimeWindowKey,
  stringToISODate,
  ISODateToString,
  truncateZerosInDateTime,
  isDateTimePickerInputValid,
} from './date_time_picker_lib';

const events = {
  apply: 'apply',
  invalid: 'invalid',
};

export default {
  components: {
    Icon,
    DateTimePickerInput,
    GlFormGroup,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    start: {
      type: String,
      required: true,
    },
    end: {
      type: String,
      required: true,
    },
    timeWindows: {
      type: Object,
      required: false,
      default: () => defaultTimeWindows,
    },
  },
  data() {
    return {
      startDate: this.start,
      endDate: this.end,
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
      },
    },
    endInput: {
      get() {
        return this.endInputValid ? this.formatDate(this.endDate) : this.endDate;
      },
      set(val) {
        // Attempt to set a formatted date if possible
        this.endDate = isDateTimePickerInputValid(val) ? stringToISODate(val) : val;
      },
    },

    timeWindowText() {
      const timeWindow = getTimeWindowKey({ start: this.start, end: this.end }, this.timeWindows);
      if (timeWindow) {
        return this.timeWindows[timeWindow].label;
      } else if (isValidDate(this.start) && isValidDate(this.end)) {
        return sprintf(__('%{start} to %{end}'), {
          start: this.formatDate(this.start),
          end: this.formatDate(this.end),
        });
      }
      return '';
    },
  },
  mounted() {
    // Validate on mounted, and trigger an update if needed
    if (!this.isValid) {
      this.$emit(events.invalid);
    }
  },
  methods: {
    formatDate(date) {
      return truncateZerosInDateTime(ISODateToString(date));
    },
    setTimeWindow(key) {
      const { start, end } = getTimeRange(key, this.timeWindows);
      this.startDate = start;
      this.endDate = end;

      this.apply();
    },
    closeDropdown() {
      this.$refs.dropdown.hide();
    },
    apply() {
      this.$emit(events.apply, {
        start: this.startDate,
        end: this.endDate,
      });
    },
  },
};
</script>
<template>
  <gl-dropdown :text="timeWindowText" class="date-time-picker" menu-class="date-time-picker-menu">
    <div class="d-flex justify-content-between gl-p-2">
      <gl-form-group
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
          <gl-button @click="closeDropdown">{{ __('Cancel') }}</gl-button>
          <gl-button variant="success" :disabled="!isValid" @click="apply()">
            {{ __('Apply') }}
          </gl-button>
        </gl-form-group>
      </gl-form-group>
      <gl-form-group label-for="group-id-dropdown" class="col-md-5 gl-pl-1 gl-pr-1 m-0">
        <template #label>
          <span class="gl-pl-5">{{ __('Quick range') }}</span>
        </template>
        <gl-dropdown-item
          v-for="(timeWindow, key) in timeWindows"
          :key="key"
          :active="timeWindow.label === timeWindowText"
          active-class="active"
          @click="setTimeWindow(key)"
        >
          <icon
            name="mobile-issue-close"
            class="align-bottom"
            :class="{ invisible: timeWindow.label !== timeWindowText }"
          />
          {{ timeWindow.label }}
        </gl-dropdown-item>
      </gl-form-group>
    </div>
  </gl-dropdown>
</template>
