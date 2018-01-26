import _ from 'underscore';

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
    this.$dropdown.glDropdown({
      data: this.getData.bind(this),
      filterable: true,
      remote: false,
      search: {
        fields: ['title'],
      },
      selectable: true,
      toggleLabel(selected) {
        return (selected && 'id' in selected) ? selected.title : this.defaultToggleLabel;
      },
      fieldName: this.fieldName,
      text(item) {
        return _.escape(item.title);
      },
      id(item) {
        return _.escape(item.id);
      },
      onFilter: this.toggleCreateNewButton.bind(this),
      clicked: (options) => {
        options.e.preventDefault();
        this.onSelect();
      },
    });
  }

  bindEvents() {
    this.$createButton.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard(e) {
    e.preventDefault();

    // Refresh the dropdown's data, which ends up calling `getData`
    this.$dropdown.data('glDropdown').remote.execute();
    this.$dropdown.data('glDropdown').selectRowAtIndex();
  }

  getData(term, callback) {
    this.getDataOption(term, (data = []) => {
      // Ensure the selected item isn't already in the data to avoid duplicates
      const alreadyHasSelectedItem = this.selectedItem && data.some(item =>
        item.id === this.selectedItem.id,
      );

      let uniqueData = data;
      if (!alreadyHasSelectedItem) {
        uniqueData = data.concat(this.selectedItem || []);
      }

      callback(uniqueData);
    });
  }

  toggleCreateNewButton(item) {
    if (item) {
      this.selectedItem = {
        title: item,
        id: item,
        text: item,
      };

      this.$dropdownContainer
        .find('.js-dropdown-create-new-item code')
        .text(item);
    }

    this.toggleFooter(!item);
  }

  toggleFooter(toggleState) {
    this.$dropdownFooter.toggleClass('hidden', toggleState);
  }
}
