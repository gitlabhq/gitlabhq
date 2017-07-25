export default class ProtectedTagDropdown {
  /**
   * @param {Object} options containing
   *                         `$dropdown` target element
   *                          `onSelect` event callback
   * $dropdown must be an element created using `dropdown_tag()` rails helper
   */
  constructor(options) {
    this.onSelect = options.onSelect;
    this.$dropdown = options.$dropdown;
    this.$dropdownContainer = this.$dropdown.parent();
    this.$dropdownFooter = this.$dropdownContainer.find('.dropdown-footer');
    this.$protectedTag = this.$dropdownContainer.find('.js-create-new-protected-tag');

    this.buildDropdown();
    this.bindEvents();

    // Hide footer
    this.toggleFooter(true);
  }

  buildDropdown() {
    this.$dropdown.glDropdown({
      data: this.getProtectedTags.bind(this),
      filterable: true,
      remote: false,
      search: {
        fields: ['title'],
      },
      selectable: true,
      toggleLabel(selected) {
        return (selected && 'id' in selected) ? selected.title : 'Protected Tag';
      },
      fieldName: 'protected_tag[name]',
      text(protectedTag) {
        return _.escape(protectedTag.title);
      },
      id(protectedTag) {
        return _.escape(protectedTag.id);
      },
      onFilter: this.toggleCreateNewButton.bind(this),
      clicked: (options) => {
        options.e.preventDefault();
        this.onSelect();
      },
    });
  }

  bindEvents() {
    this.$protectedTag.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard(e) {
    this.$dropdown.data('glDropdown').remote.execute();
    this.$dropdown.data('glDropdown').selectRowAtIndex();
    e.preventDefault();
  }

  getProtectedTags(term, callback) {
    if (this.selectedTag) {
      callback(gon.open_tags.concat(this.selectedTag));
    } else {
      callback(gon.open_tags);
    }
  }

  toggleCreateNewButton(tagName) {
    if (tagName) {
      this.selectedTag = {
        title: tagName,
        id: tagName,
        text: tagName,
      };

      this.$dropdownContainer
        .find('.js-create-new-protected-tag code')
        .text(tagName);
    }

    this.toggleFooter(!tagName);
  }

  toggleFooter(toggleState) {
    this.$dropdownFooter.toggleClass('hidden', toggleState);
  }
}
