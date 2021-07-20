<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { dateInWords } from '../../../lib/utils/datetime_utility';
import datePicker from '../pikaday.vue';
import collapsedCalendarIcon from './collapsed_calendar_icon.vue';
import toggleSidebar from './toggle_sidebar.vue';

export default {
  name: 'SidebarDatePicker',
  components: {
    datePicker,
    toggleSidebar,
    collapsedCalendarIcon,
    GlLoadingIcon,
  },
  props: {
    blockClass: {
      type: String,
      required: false,
      default: '',
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: true,
    },
    showToggleSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
      default: __('Date picker'),
    },
    selectedDate: {
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
      default: null,
    },
  },
  data() {
    return {
      editing: false,
    };
  },
  computed: {
    selectedAndEditable() {
      return this.selectedDate && this.editable;
    },
    selectedDateWords() {
      return dateInWords(this.selectedDate, true);
    },
    collapsedText() {
      return this.selectedDateWords ? this.selectedDateWords : __('None');
    },
  },
  methods: {
    stopEditing() {
      this.editing = false;
    },
    toggleDatePicker() {
      this.editing = !this.editing;
    },
    newDateSelected(date = null) {
      this.date = date;
      this.editing = false;
      this.$emit('saveDate', date);
    },
    toggleSidebar() {
      this.$emit('toggleCollapse');
    },
  },
};
</script>

<template>
  <div :class="blockClass" class="block">
    <div class="issuable-sidebar-header">
      <toggle-sidebar :collapsed="collapsed" @toggle="toggleSidebar" />
    </div>
    <collapsed-calendar-icon :text="collapsedText" class="sidebar-collapsed-icon" />
    <div class="title">
      {{ label }}
      <gl-loading-icon v-if="isLoading" size="sm" :inline="true" />
      <div class="float-right">
        <button
          v-if="editable && !editing"
          type="button"
          class="btn-blank btn-link btn-primary-hover-link btn-sidebar-action"
          @click="toggleDatePicker"
        >
          {{ __('Edit') }}
        </button>
        <toggle-sidebar v-if="showToggleSidebar" :collapsed="collapsed" @toggle="toggleSidebar" />
      </div>
    </div>
    <div class="value">
      <date-picker
        v-if="editing"
        :selected-date="selectedDate"
        :min-date="minDate"
        :max-date="maxDate"
        :label="label"
        @newDateSelected="newDateSelected"
        @hidePicker="stopEditing"
      />
      <span v-else class="value-content">
        <template v-if="selectedDate">
          <strong>{{ selectedDateWords }}</strong>
          <span v-if="selectedAndEditable" class="no-value">
            -
            <button
              type="button"
              class="btn-blank btn-link btn-secondary-hover-link"
              @click="newDateSelected(null)"
            >
              {{ __('remove') }}
            </button>
          </span>
        </template>
        <span v-else class="no-value">{{ __('None') }}</span>
      </span>
    </div>
  </div>
</template>
