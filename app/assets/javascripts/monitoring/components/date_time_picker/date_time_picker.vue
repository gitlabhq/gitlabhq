<script>
import { GlButton, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DateTimePickerInput from './date_time_picker_input.vue';
import {
  getTimeDiff,
  getTimeWindow,
  stringToISODate,
  ISODateToString,
  truncateZerosInDateTime,
  isDateTimePickerInputValid,
} from '~/monitoring/utils';
import { timeWindows } from '~/monitoring/constants';

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
    timeWindows: {
      type: Object,
      required: false,
      default: () => timeWindows,
    },
    selectedTimeWindow: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      selectedTimeWindowText: '',
      customTime: {
        from: null,
        to: null,
      },
    };
  },
  computed: {
    applyEnabled() {
      return Boolean(this.inputState.from && this.inputState.to);
    },
    inputState() {
      const { from, to } = this.customTime;
      return {
        from: from && isDateTimePickerInputValid(from),
        to: to && isDateTimePickerInputValid(to),
      };
    },
  },
  watch: {
    selectedTimeWindow() {
      this.verifyTimeRange();
    },
  },
  mounted() {
    this.verifyTimeRange();
  },
  methods: {
    activeTimeWindow(key) {
      return this.timeWindows[key] === this.selectedTimeWindowText;
    },
    setCustomTimeWindowParameter() {
      this.$emit('onApply', {
        start: stringToISODate(this.customTime.from),
        end: stringToISODate(this.customTime.to),
      });
    },
    setTimeWindowParameter(key) {
      const { start, end } = getTimeDiff(key);
      this.$emit('onApply', {
        start,
        end,
      });
    },
    closeDropdown() {
      this.$refs.dropdown.hide();
    },
    verifyTimeRange() {
      const range = getTimeWindow(this.selectedTimeWindow);
      if (range) {
        this.selectedTimeWindowText = this.timeWindows[range];
      } else {
        this.customTime = {
          from: truncateZerosInDateTime(ISODateToString(this.selectedTimeWindow.start)),
          to: truncateZerosInDateTime(ISODateToString(this.selectedTimeWindow.end)),
        };
        this.selectedTimeWindowText = sprintf(s__('%{from} to %{to}'), this.customTime);
      }
    },
  },
};
</script>
<template>
  <gl-dropdown
    ref="dropdown"
    :text="selectedTimeWindowText"
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
          v-model="customTime.from"
          :label="__('From')"
          :state="inputState.from"
        />
        <date-time-picker-input
          id="custom-time-to"
          v-model="customTime.to"
          :label="__('To')"
          :state="inputState.to"
        />
        <gl-form-group>
          <gl-button @click="closeDropdown">{{ __('Cancel') }}</gl-button>
          <gl-button
            variant="success"
            :disabled="!applyEnabled"
            @click="setCustomTimeWindowParameter"
            >{{ __('Apply') }}</gl-button
          >
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
          :active="activeTimeWindow(key)"
          active-class="active"
          @click="setTimeWindowParameter(key)"
        >
          <icon
            name="mobile-issue-close"
            class="align-bottom"
            :class="{ invisible: !activeTimeWindow(key) }"
          />
          {{ value }}
        </gl-dropdown-item>
      </gl-form-group>
    </div>
  </gl-dropdown>
</template>
