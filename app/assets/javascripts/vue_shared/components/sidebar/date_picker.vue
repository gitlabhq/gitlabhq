<script>
  import datePicker from '../pikaday.vue';
  import loadingIcon from '../loading_icon.vue';
  import toggleSidebar from './toggle_sidebar.vue';
  import collapsedCalendarIcon from './collapsed_calendar_icon.vue';
  import { dateInWords } from '../../../lib/utils/datetime_utility';

  export default {
    name: 'SidebarDatePicker',
    components: {
      datePicker,
      toggleSidebar,
      loadingIcon,
      collapsedCalendarIcon,
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
        default: 'Date picker',
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
        return this.selectedDateWords ? this.selectedDateWords : 'None';
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
  <div
    class="block"
    :class="blockClass"
  >
    <collapsed-calendar-icon
      class="sidebar-collapsed-icon"
      :text="collapsedText"
    />
    <div class="title">
      {{ label }}
      <loading-icon
        v-if="isLoading"
        :inline="true"
      />
      <div class="pull-right">
        <button
          v-if="editable && !editing"
          type="button"
          class="btn-blank btn-link btn-primary-hover-link btn-sidebar-action"
          @click="toggleDatePicker"
        >
          Edit
        </button>
        <toggle-sidebar
          v-if="showToggleSidebar"
          :collapsed="collapsed"
          @toggle="toggleSidebar"
        />
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
      <span
        v-else
        class="value-content"
      >
        <template v-if="selectedDate">
          <strong>{{ selectedDateWords }}</strong>
          <span
            v-if="selectedAndEditable"
            class="no-value"
          >
            -
            <button
              type="button"
              class="btn-blank btn-link btn-secondary-hover-link"
              @click="newDateSelected(null)"
            >
              remove
            </button>
          </span>
        </template>
        <span
          v-else
          class="no-value"
        >
          None
        </span>
      </span>
    </div>
  </div>
</template>
