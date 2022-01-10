import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

const defaultTimezone = { identifier: 'Etc/UTC', name: 'UTC', offset: 0 };
const defaults = {
  $inputEl: null,
  $dropdownEl: null,
  onSelectTimezone: null,
  displayFormat: (item) => item.name,
};

export const formatUtcOffset = (offset) => {
  const parsed = parseInt(offset, 10);
  if (Number.isNaN(parsed) || parsed === 0) {
    return `0`;
  }
  const prefix = offset > 0 ? '+' : '-';
  return `${prefix} ${Math.abs(offset / 3600)}`;
};

export const formatTimezone = (item) => `[UTC ${formatUtcOffset(item.offset)}] ${item.name}`;

export const findTimezoneByIdentifier = (tzList = [], identifier = null) => {
  if (tzList && tzList.length && identifier && identifier.length) {
    return tzList.find((tz) => tz.identifier === identifier) || null;
  }
  return null;
};

export default class TimezoneDropdown {
  constructor({
    $dropdownEl,
    $inputEl,
    onSelectTimezone,
    displayFormat,
    allowEmpty = false,
  } = defaults) {
    this.$dropdown = $dropdownEl;
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');
    this.$input = $inputEl;
    this.timezoneData = this.$dropdown.data('data') || [];

    this.onSelectTimezone = onSelectTimezone;
    this.displayFormat = displayFormat || defaults.displayFormat;
    this.allowEmpty = allowEmpty;

    this.initDropdown();
  }

  initDropdown() {
    initDeprecatedJQueryDropdown(this.$dropdown, {
      data: this.timezoneData,
      filterable: true,
      selectable: true,
      toggleLabel: this.displayFormat,
      search: {
        fields: ['name'],
      },
      clicked: (cfg) => this.handleDropdownChange(cfg),
      text: (item) => formatTimezone(item),
    });

    const initialTimezone = findTimezoneByIdentifier(this.timezoneData, this.$input.val());

    if (initialTimezone !== null) {
      this.setDropdownValue(initialTimezone);
    } else if (!this.allowEmpty) {
      this.setDropdownValue(defaultTimezone);
    }
  }

  setDropdownValue(timezone) {
    this.$dropdownToggle.text(this.displayFormat(timezone));
    this.$input.val(timezone.identifier);
  }

  handleDropdownChange({ selectedObj, e }) {
    e.preventDefault();
    this.$input.val(selectedObj.identifier);
    if (this.onSelectTimezone) {
      this.onSelectTimezone({ selectedObj, e });
    }
  }
}
