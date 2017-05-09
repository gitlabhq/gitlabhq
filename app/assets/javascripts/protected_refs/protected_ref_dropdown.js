export default class ProtectedRefDropdown {
  /**
   * @param {Object} options containing
   *                         `$dropdown` target element
   *                         `onSelect` event callback
   * $dropdown must be an element created using `dropdown_tag()` rails helper
   *
   * @param {Object} config containing
   *                        `$dropdownFooter` element
   *                        `$createNewProtectedRef` element
   *                        `protectedRefFieldName` string
   *                        `dropdownLabel` string
   *                        `protectedRefsList` array
   */
  constructor(options, config) {
    this.onSelect = options.onSelect;
    this.$dropdown = options.$dropdown;
    this.$dropdownContainer = this.$dropdown.parent();

    this.$dropdownFooter = config.$dropdownFooter;
    this.$createNewProtectedRef = config.$createNewProtectedRef;
    this.protectedRefsList = config.protectedRefsList;

    this.buildDropdown(config);
    this.bindEvents();

    // Hide footer
    this.toggleFooter(true);
  }

  buildDropdown(config) {
    const { dropdownLabel, protectedRefFieldName } = config;

    this.$dropdown.glDropdown({
      data: this.getProtectedRefs.bind(this),
      filterable: true,
      remote: false,
      search: {
        fields: ['title'],
      },
      selectable: true,
      fieldName: protectedRefFieldName,
      onFilter: this.toggleCreateNewButton.bind(this),
      toggleLabel(selected) {
        return (selected && 'id' in selected) ? selected.title : dropdownLabel;
      },
      text(protectedRef) {
        return _.escape(protectedRef.title);
      },
      id(protectedRef) {
        return _.escape(protectedRef.id);
      },
      clicked: (options) => {
        options.e.preventDefault();
        this.onSelect();
      },
    });
  }

  bindEvents() {
    this.$createNewProtectedRef.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard(e) {
    e.preventDefault();

    // Refresh the dropdown's data, which ends up calling `getProtectedRefs`
    this.$dropdown.data('glDropdown').remote.execute();
    this.$dropdown.data('glDropdown').selectRowAtIndex();
  }

  getProtectedRefs(term, callback) {
    if (this.selectedRef) {
      callback(this.protectedRefsList.concat(this.selectedRef));
    } else {
      callback(this.protectedRefsList);
    }
  }

  toggleCreateNewButton(refName) {
    if (refName) {
      this.selectedRef = {
        title: refName,
        id: refName,
        text: refName,
      };

      this.$createNewProtectedRef.find('code').text(refName);
    }

    this.toggleFooter(!refName);
  }

  toggleFooter(toggleState) {
    this.$dropdownFooter.toggleClass('hidden', toggleState);
  }
}
