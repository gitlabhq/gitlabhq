export default class ProtectedBranchDropdown {
  /**
   * @param {Object} options containing
   *                         `$dropdown` target element
   *                          `onSelect` event callback
   * $dropdown must be an element created using `dropdown_branch()` rails helper
   */
  constructor(options) {
    this.onSelect = options.onSelect;
    this.$dropdown = options.$dropdown;
    this.$dropdownContainer = this.$dropdown.parent();
    this.$dropdownFooter = this.$dropdownContainer.find('.dropdown-footer');
    this.$protectedBranch = this.$dropdownContainer.find('.js-create-new-protected-branch');

    this.buildDropdown();
    this.bindEvents();

    // Hide footer
    this.toggleFooter(true);
  }

  buildDropdown() {
    this.$dropdown.glDropdown({
      data: this.getProtectedBranches.bind(this),
      filterable: true,
      remote: false,
      search: {
        fields: ['title'],
      },
      selectable: true,
      toggleLabel(selected) {
        return (selected && 'id' in selected) ? selected.title : 'Protected Branch';
      },
      fieldName: 'protected_branch[name]',
      text(protectedBranch) {
        return _.escape(protectedBranch.title);
      },
      id(protectedBranch) {
        return _.escape(protectedBranch.id);
      },
      onFilter: this.toggleCreateNewButton.bind(this),
      clicked: (options) => {
        options.e.preventDefault();
        this.onSelect();
      },
    });
  }

  bindEvents() {
    this.$protectedBranch.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard(e) {
    e.preventDefault();

    // Refresh the dropdown's data, which ends up calling `getProtectedBranches`
    this.$dropdown.data('glDropdown').remote.execute();
    this.$dropdown.data('glDropdown').selectRowAtIndex();
  }

  getProtectedBranches(term, callback) {
    if (this.selectedBranch) {
      callback(gon.open_branches.concat(this.selectedBranch));
    } else {
      callback(gon.open_branches);
    }
  }

  toggleCreateNewButton(branchName) {
    if (branchName) {
      this.selectedBranch = {
        title: branchName,
        id: branchName,
        text: branchName,
      };

      this.$dropdownContainer
        .find('.js-create-new-protected-branch code')
        .text(branchName);
    }

    this.toggleFooter(!branchName);
  }

  toggleFooter(toggleState) {
    this.$dropdownFooter.toggleClass('hidden', toggleState);
  }
}
