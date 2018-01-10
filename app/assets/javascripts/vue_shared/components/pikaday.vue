<script>
  import Pikaday from 'pikaday';
  import { parsePikadayDate, pikadayToString } from '../../lib/utils/datefix';

  export default {
    name: 'DatePicker',
    props: {
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
    mounted() {
      this.calendar = new Pikaday({
        field: this.$el.querySelector('.dropdown-menu-toggle'),
        theme: 'gitlab-theme animate-picker',
        format: 'yyyy-mm-dd',
        container: this.$el,
        defaultDate: this.selectedDate,
        setDefaultDate: !!this.selectedDate,
        minDate: this.minDate,
        maxDate: this.maxDate,
        parse: dateString => parsePikadayDate(dateString),
        toString: date => pikadayToString(date),
        onSelect: this.selected.bind(this),
        onClose: this.toggled.bind(this),
      });

      this.$el.append(this.calendar.el);
      this.calendar.show();
    },
    beforeDestroy() {
      this.calendar.destroy();
    },
    methods: {
      selected(dateText) {
        this.$emit('newDateSelected', this.calendar.toString(dateText));
      },
      toggled() {
        this.$emit('hidePicker');
      },
    },
  };
</script>

<template>
  <div class="pikaday-container">
    <div class="dropdown open">
      <button
        type="button"
        class="dropdown-menu-toggle"
        data-toggle="dropdown"
        @click="toggled"
      >
        <span class="dropdown-toggle-text">
          {{ label }}
        </span>
        <i
          class="fa fa-chevron-down"
          aria-hidden="true"
        >
        </i>
      </button>
    </div>
  </div>
</template>
