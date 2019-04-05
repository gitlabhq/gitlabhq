const defaultTimezone = 'UTC';

export const formatUtcOffset = offset => {
  const parsed = parseInt(offset, 10);
  if (Number.isNaN(parsed) || parsed === 0) {
    return `0`;
  }
  const prefix = offset > 0 ? '+' : '-';
  return `${prefix} ${Math.abs(offset / 3600)}`;
};

export const formatTimezone = item => `[UTC ${formatUtcOffset(item.offset)}] ${item.name}`;

const defaults = {
  $inputEl: null,
  $dropdownEl: null,
  onSelectTimezone: null,
};

export default class TimezoneDropdown {
  constructor({ $dropdownEl, $inputEl, onSelectTimezone } = defaults) {
    this.$dropdown = $dropdownEl;
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');
    this.$input = $inputEl;
    this.timezoneData = this.$dropdown.data('data');

    this.initDefaultTimezone();
    this.initDropdown();

    this.onSelectTimezone = onSelectTimezone;
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
      text: item => formatTimezone(item),
    });

    this.setDropdownToggle();
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
    if (this.onSelectTimezone) {
      this.onSelectTimezone({ selectedObj, e });
    }
  }
}
