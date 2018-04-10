/* eslint-disable class-methods-use-this */

import $ from 'jquery';

const defaultTimezone = 'UTC';

export default class TimezoneDropdown {
  constructor() {
    this.$dropdown = $('.js-timezone-dropdown');
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');
    this.$input = $('#schedule_cron_timezone');
    this.timezoneData = this.$dropdown.data('data');
    this.initDefaultTimezone();
    this.initDropdown();
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.timezoneData,
      filterable: true,
      selectable: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: cfg => this.updateInputValue(cfg),
      text: item => this.formatTimezone(item),
    });

    this.setDropdownToggle();
  }

  formatUtcOffset(offset) {
    let prefix = '';

    if (offset > 0) {
      prefix = '+';
    } else if (offset < 0) {
      prefix = '-';
    }

    return `${prefix} ${Math.abs(offset / 3600)}`;
  }

  formatTimezone(item) {
    return `[UTC ${this.formatUtcOffset(item.offset)}] ${item.name}`;
  }

  initDefaultTimezone() {
    const initialValue = this.$input.val();

    if (!initialValue) {
      this.$input.val(defaultTimezone);
    }
  }

  setDropdownToggle() {
    const initialValue = this.$input.val();

    this.$dropdownToggle.text(initialValue);
  }

  updateInputValue({ selectedObj, e }) {
    e.preventDefault();
    this.$input.val(selectedObj.identifier);
    gl.pipelineScheduleFieldErrors.updateFormValidityState();
  }
}
