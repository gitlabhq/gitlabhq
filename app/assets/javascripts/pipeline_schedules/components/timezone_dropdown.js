/* eslint-disable class-methods-use-this */

export default class TimezoneDropdown {
  constructor() {
    this.$dropdown = $('.js-timezone-dropdown');
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');
    this.$input = $('#schedule_cron_timezone');
    this.timezoneData = this.$dropdown.data('data');
    this.initialValue = this.$input.val();
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

  setDropdownToggle() {
    if (this.initialValue) {
      this.$dropdownToggle.text(this.initialValue);
    }
  }

  updateInputValue({ selectedObj, e }) {
    e.preventDefault();
    this.$input.val(selectedObj.identifier);
    gl.pipelineScheduleFieldErrors.updateFormValidityState();
  }
}
