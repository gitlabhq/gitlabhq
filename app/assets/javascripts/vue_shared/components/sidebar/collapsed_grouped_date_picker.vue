<script>
import { __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { dateInWords, timeFor } from '~/lib/utils/datetime_utility';
import collapsedCalendarIcon from './collapsed_calendar_icon.vue';

export default {
  name: 'SidebarCollapsedGroupedDatePicker',
  components: {
    collapsedCalendarIcon,
  },
  mixins: [timeagoMixin],
  props: {
    collapsed: {
      type: Boolean,
      required: false,
      default: true,
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
    disableClickableIcons: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasMinAndMaxDates() {
      return this.minDate && this.maxDate;
    },
    hasNoMinAndMaxDates() {
      return !this.minDate && !this.maxDate;
    },
    showMinDateBlock() {
      return this.minDate || this.hasNoMinAndMaxDates;
    },
    showFromText() {
      return !this.maxDate && this.minDate;
    },
    iconClass() {
      const disabledClass = this.disableClickableIcons ? 'disabled' : '';
      return `sidebar-collapsed-icon calendar-icon ${disabledClass}`;
    },
  },
  methods: {
    toggleSidebar() {
      this.$emit('toggleCollapse');
    },
    dateText(dateType = 'min') {
      const date = this[`${dateType}Date`];
      const dateWords = dateInWords(date, true);
      const parsedDateWords = dateWords ? dateWords.replace(',', '') : dateWords;

      return date ? parsedDateWords : __('None');
    },
    tooltipText(dateType = 'min') {
      const defaultText = dateType === 'min' ? __('Start date') : __('Due date');
      const date = this[`${dateType}Date`];
      const timeAgo = dateType === 'min' ? this.timeFormatted(date) : timeFor(date);
      const dateText = date ? [this.dateText(dateType), `(${timeAgo})`].join(' ') : '';

      if (date) {
        return [defaultText, dateText].join('<br />');
      }
      return __('Start and due date');
    },
  },
};
</script>

<template>
  <div class="block sidebar-grouped-item gl-cursor-pointer" role="button" @click="toggleSidebar">
    <collapsed-calendar-icon
      v-if="showMinDateBlock"
      :container-class="iconClass"
      :tooltip-text="tooltipText('min')"
    >
      <span class="sidebar-collapsed-value">
        <span v-if="showFromText">{{ __('From') }}</span> <span>{{ dateText('min') }}</span>
      </span>
    </collapsed-calendar-icon>
    <div v-if="hasMinAndMaxDates" class="text-center sidebar-collapsed-divider">-</div>
    <collapsed-calendar-icon
      v-if="maxDate"
      :container-class="iconClass"
      :tooltip-text="tooltipText('max')"
    >
      <span class="sidebar-collapsed-value">
        <span v-if="!minDate">{{ __('Until') }}</span> <span>{{ dateText('max') }}</span>
      </span>
    </collapsed-calendar-icon>
  </div>
</template>
