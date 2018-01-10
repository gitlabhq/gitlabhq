<script>
  import { dateInWords } from '../../../lib/utils/datetime_utility';
  import toggleSidebar from './toggle_sidebar.vue';
  import collapsedCalendarIcon from './collapsed_calendar_icon.vue';

  export default {
    name: 'SidebarCollapsedGroupedDatePicker',
    components: {
      toggleSidebar,
      collapsedCalendarIcon,
    },
    props: {
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
        return `block sidebar-collapsed-icon calendar-icon ${disabledClass}`;
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

        return date ? parsedDateWords : 'None';
      },
    },
  };
</script>

<template>
  <div class="block sidebar-grouped-item">
    <div
      v-if="showToggleSidebar"
      class="issuable-sidebar-header"
    >
      <toggle-sidebar
        :collapsed="collapsed"
        @toggle="toggleSidebar"
      />
    </div>
    <collapsed-calendar-icon
      v-if="showMinDateBlock"
      :container-class="iconClass"
      @click="toggleSidebar"
    >
      <span class="sidebar-collapsed-value">
        <span v-if="showFromText">From</span>
        <span>{{ dateText('min') }}</span>
      </span>
    </collapsed-calendar-icon>
    <div
      v-if="hasMinAndMaxDates"
      class="text-center sidebar-collapsed-divider"
    >
      -
    </div>
    <collapsed-calendar-icon
      v-if="maxDate"
      :container-class="iconClass"
      :show-icon="!minDate"
      @click="toggleSidebar"
    >
      <span class="sidebar-collapsed-value">
        <span v-if="!minDate">Until</span>
        <span>{{ dateText('max') }}</span>
      </span>
    </collapsed-calendar-icon>
  </div>
</template>
