<script>
import { GlButton, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DateTimePickerInput from './date_time_picker_input.vue';
import {
  getTimeDiff,
  isValidDate,
  getTimeWindow,
  stringToISODate,
  ISODateToString,
  truncateZerosInDateTime,
  isDateTimePickerInputValid,
} from '~/monitoring/utils';

import { timeWindows } from '~/monitoring/constants';

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
      default: () => timeWindows,
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
      const timeWindow = getTimeWindow({ start: this.start, end: this.end });
      if (timeWindow) {
        return this.timeWindows[timeWindow];
      } else if (isValidDate(this.start) && isValidDate(this.end)) {
        return sprintf(s__('%{start} to %{end}'), {
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
      const { start, end } = getTimeDiff(key);
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
  <gl-dropdown
    ref="dropdown"
    :text="timeWindowText"
    menu-class="time-window-dropdown-menu"
    class="js-time-window-dropdown"
  >
    <div class="d-flex justify-content-between time-window-dropdown-menu-container">
      <gl-form-group
        :label="__('Custom range')"
        label-for="custom-from-time"
        class="custom-time-range-form-group col-md-7 p-0 m-0"
      >
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
        <gl-form-group>
          <gl-button @click="closeDropdown">{{ __('Cancel') }}</gl-button>
          <gl-button variant="success" :disabled="!isValid" @click="apply()">
            {{ __('Apply') }}
          </gl-button>
        </gl-form-group>
      </gl-form-group>
      <gl-form-group
        :label="__('Quick range')"
        label-for="group-id-dropdown"
        label-align="center"
        class="col-md-4 p-0 m-0"
      >
        <gl-dropdown-item
          v-for="(value, key) in timeWindows"
          :key="key"
          :active="value === timeWindowText"
          active-class="active"
          @click="setTimeWindow(key)"
        >
          <icon
            name="mobile-issue-close"
            class="align-bottom"
            :class="{ invisible: value !== timeWindowText }"
          />
          {{ value }}
        </gl-dropdown-item>
      </gl-form-group>
    </div>
  </gl-dropdown>
</template>
