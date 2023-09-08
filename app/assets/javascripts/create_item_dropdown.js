import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default class CreateItemDropdown {
  /**
   * @param {Object} options containing
   *                         `$dropdown` target element
   *                          `onSelect` event callback
   * $dropdown must be an element created using `dropdown_tag()` rails helper
   */
  constructor(options) {
    this.defaultToggleLabel = options.defaultToggleLabel;
    this.fieldName = options.fieldName;
    this.onSelect = options.onSelect || (() => {});
    this.getDataOption = options.getData;
    this.getDataRemote = Boolean(options.filterRemote);
    this.createNewItemFromValueOption = options.createNewItemFromValue;
    this.$dropdown = options.$dropdown;
    this.$dropdownContainer = this.$dropdown.parent();
    this.$dropdownFooter = this.$dropdownContainer.find('.dropdown-footer');
    this.$createButton = this.$dropdownContainer.find('.js-dropdown-create-new-item');

    this.buildDropdown();
    this.bindEvents();

    // Hide footer
    this.toggleFooter(true);
  }

  buildDropdown() {
    initDeprecatedJQueryDropdown(this.$dropdown, {
      data: this.getData.bind(this),
      filterable: true,
      filterRemote: this.getDataRemote,
      search: {
        fields: ['text'],
      },
      selectable: true,
      toggleLabel(selected) {
        return selected && 'id' in selected ? selected.title : this.defaultToggleLabel;
      },
      fieldName: this.fieldName,
      text(item) {
        return item.text;
      },
      id(item) {
        return item.id;
      },
      onFilter: this.toggleCreateNewButton.bind(this),
      clicked: (options) => {
        options.e.preventDefault();
        this.onSelect();
      },
    });
  }

  clearDropdown() {
    this.$dropdownContainer.find('.dropdown-content').html('');
    this.$dropdownContainer.find('.dropdown-input-field').val('');
  }

  bindEvents() {
    this.$createButton.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard(e) {
    e.preventDefault();

    this.refreshData();
    this.$dropdown.data('deprecatedJQueryDropdown').selectRowAtIndex();
  }

  refreshData() {
    // Refresh the dropdown's data, which ends up calling `getData`
    this.$dropdown.data('deprecatedJQueryDropdown').remote.execute();
  }

  getData(term, callback) {
    this.getDataOption(term, (data = []) => {
      // Ensure the selected item isn't already in the data to avoid duplicates
      const alreadyHasSelectedItem =
        this.selectedItem && data.some((item) => item.id === this.selectedItem.id);

      let uniqueData = data;
      if (!alreadyHasSelectedItem) {
        uniqueData = data.concat(this.selectedItem || []);
      }

      callback(uniqueData);
    });
  }

  createNewItemFromValue(newValue) {
    if (this.createNewItemFromValueOption) {
      return this.createNewItemFromValueOption(newValue);
    }

    return {
      title: newValue,
      id: newValue,
      text: newValue,
    };
  }

  toggleCreateNewButton(newValue) {
    if (newValue) {
      this.selectedItem = this.createNewItemFromValue(newValue);

      this.$dropdownContainer.find('.js-dropdown-create-new-item code').text(newValue);
    }

    this.toggleFooter(!newValue);
  }

  toggleFooter(toggleState) {
    this.$dropdownFooter.toggleClass('hidden', toggleState);
  }

  close() {
    this.$dropdown.data('deprecatedJQueryDropdown')?.close();
  }
}
