<script>
import _ from 'underscore';
import { __, s__ } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';
import tooltip from '~/vue_shared/directives/tooltip';
import popover from '~/vue_shared/directives/popover';
import Icon from '~/vue_shared/components/icon.vue';
import DatePicker from '~/vue_shared/components/pikaday.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import CollapsedCalendarIcon from '~/vue_shared/components/sidebar/collapsed_calendar_icon.vue';

const label = __('Date picker');
const pickerLabel = __('Fixed date');

export default {
  directives: {
    tooltip,
    popover,
  },
  components: {
    Icon,
    DatePicker,
    LoadingIcon,
    CollapsedCalendarIcon,
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
      default: label,
    },
    datePickerLabel: {
      type: String,
      required: false,
      default: pickerLabel,
    },
    selectedDate: {
      type: Date,
      required: false,
      default: null,
    },
    selectedDateIsFixed: {
      type: Boolean,
      required: false,
      default: true,
    },
    dateFromMilestones: {
      type: Date,
      required: false,
      default: null,
    },
    dateFixed: {
      type: Date,
      required: false,
      default: null,
    },
    dateFromMilestonesTooltip: {
      type: String,
      required: false,
      default: '',
    },
    isDateInvalid: {
      type: Boolean,
      required: false,
      default: true,
    },
    dateInvalidTooltip: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      fieldName: _.uniqueId('dateType_'),
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
    dateFixedWords() {
      return dateInWords(this.dateFixed, true);
    },
    dateFromMilestonesWords() {
      return this.dateFromMilestones ? dateInWords(this.dateFromMilestones, true) : __('None');
    },
    collapsedText() {
      return this.selectedDateWords ? this.selectedDateWords : __('None');
    },
    popoverOptions() {
      return this.getPopoverConfig({
        title: s__('Epics|These dates affect how your epics appear in the roadmap. Dates from milestones come from the milestones assigned to issues in the epic. You can also set fixed dates or remove them entirely.'),
        content: `
          <a href="https://docs.gitlab.com/ee/user/group/epics/#Dates">${s__('Epics|More information')}</a>
        `,
      });
    },
    dateInvalidPopoverOptions() {
      return this.getPopoverConfig({
        title: this.dateInvalidTooltip,
        content: `
          <a href="https://docs.gitlab.com/ee/user/group/epics/#Dates">${s__('Epics|How can I solve this?')}</a>
        `,
      });
    },
  },
  methods: {
    getPopoverConfig({ title, content }) {
      return {
        html: true,
        trigger: 'focus',
        container: 'body',
        boundary: 'viewport',
        template: `
          <div class="popover" role="tooltip">
            <div class="arrow"></div>
            <div class="popover-header"></div>
            <div class="popover-body"></div>
          </div>
        `,
        title,
        content,
      };
    },
    stopEditing() {
      this.editing = false;
      this.$emit('toggleDateType', true, true);
    },
    toggleDatePicker() {
      this.editing = !this.editing;
    },
    newDateSelected(date = null) {
      this.editing = false;
      this.$emit('saveDate', date);
    },
    toggleDateType(dateTypeFixed) {
      this.$emit('toggleDateType', dateTypeFixed);
    },
  },
};
</script>

<template>
  <div
    :class="blockClass"
    class="block date"
  >
    <collapsed-calendar-icon
      :text="collapsedText"
      class="sidebar-collapsed-icon"
    />
    <div class="title">
      {{ label }}
      <loading-icon
        v-if="isLoading"
        :inline="true"
      />
      <div class="float-right d-flex">
        <icon
          v-popover="popoverOptions"
          name="question-o"
          css-classes="help-icon append-right-5"
          tab-index="0"
        />
        <button
          v-show="editable && !editing"
          type="button"
          class="btn-blank btn-link btn-primary-hover-link btn-sidebar-action"
          @click="toggleDatePicker"
        >
          {{ __('Edit') }}
        </button>
      </div>
    </div>
    <div class="value">
      <div
        :class="{ 'is-option-selected': selectedDateIsFixed, 'd-flex': !editing }"
        class="value-type-fixed"
      >
        <input
          v-if="!editing && editable"
          :name="fieldName"
          :checked="selectedDateIsFixed"
          type="radio"
          @click="toggleDateType(true)"
        />
        <span
          v-show="!editing"
          class="prepend-left-5"
        >{{ __('Fixed:') }}</span>
        <date-picker
          v-if="editing"
          :selected-date="dateFixed"
          :label="datePickerLabel"
          @newDateSelected="newDateSelected"
          @hidePicker="stopEditing"
        />
        <span
          v-else
          class="d-flex value-content"
        >
          <template v-if="dateFixed">
            <span>{{ dateFixedWords }}</span>
            <icon
              v-popover="dateInvalidPopoverOptions"
              v-if="isDateInvalid && selectedDateIsFixed"
              name="warning"
              css-classes="date-warning-icon append-right-5 prepend-left-5"
              tab-index="0"
            />
            <span
              v-if="selectedAndEditable"
              class="no-value"
            >
              -
              <button
                type="button"
                class="btn-blank btn-link btn-default-hover-link"
                @click="newDateSelected(null)"
              >
                {{ __('remove') }}
              </button>
            </span>
          </template>
          <span
            v-else
            class="no-value"
          >
            {{ __('None') }}
          </span>
        </span>
      </div>
      <abbr
        v-tooltip
        :title="dateFromMilestonesTooltip"
        :class="{ 'is-option-selected': !selectedDateIsFixed }"
        class="value-type-dynamic d-flex prepend-top-10"
        data-placement="bottom"
        data-html="true"
      >
        <input
          v-if="editable"
          :name="fieldName"
          :checked="!selectedDateIsFixed"
          type="radio"
          @click="toggleDateType(false)"
        />
        <span class="prepend-left-5">{{ __('From milestones:') }}</span>
        <span class="value-content">{{ dateFromMilestonesWords }}</span>
        <icon
          v-popover="dateInvalidPopoverOptions"
          v-if="isDateInvalid && !selectedDateIsFixed"
          name="warning"
          css-classes="date-warning-icon prepend-left-5"
          tab-index="0"
        />
      </abbr>
    </div>
  </div>
</template>

