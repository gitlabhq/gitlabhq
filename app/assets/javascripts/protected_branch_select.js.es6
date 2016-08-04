class ProtectedBranchDropdown {
  constructor(options) {
    this.onSelect = options.onSelect;
    this.$dropdown = options.$dropdown;
    this.$dropdownContainer = this.$dropdown.parent();
    this.$dropdownFooter = this.$dropdownContainer.find('.dropdown-footer');
    this.$protectedBranch = this.$dropdownContainer.find('.create-new-protected-branch');

    this.buildDropdown();
    this.bindEvents();

    // Hide footer
    this.$dropdownFooter.addClass('hidden');
  }

  buildDropdown() {
    this.$dropdown.glDropdown({
      data: this.getProtectedBranches.bind(this),
      filterable: true,
      remote: false,
      search: {
        fields: ['title']
      },
      selectable: true,
      toggleLabel(selected) {
        return (selected && 'id' in selected) ? selected.title : 'Protected Branch';
      },
      fieldName: 'protected_branch[name]',
      text(protected_branch) {
        return _.escape(protected_branch.title);
      },
      id(protected_branch) {
        return _.escape(protected_branch.id);
      },
      onFilter: this.toggleCreateNewButton.bind(this),
      clicked: (item, $el, e) => {
        e.preventDefault();
        this.onSelect();
      }
    });
  }

  bindEvents() {
    this.$protectedBranch.on('click', this.onClickCreateWildcard.bind(this));
  }

  onClickCreateWildcard() {
    this.$dropdown.data('glDropdown').remote.execute();
    this.$dropdown.data('glDropdown').selectRowAtIndex(0);
  }

  getProtectedBranches(term, callback) {
    if (this.selectedBranch) {
      callback(gon.open_branches.concat(this.selectedBranch));
    } else {
      callback(gon.open_branches);
    }
  }

  toggleCreateNewButton(branchName) {
    this.selectedBranch = {
      title: branchName,
      id: branchName,
      text: branchName
    };

    if (branchName) {
      this.$dropdownContainer
        .find('.create-new-protected-branch')
        .html(`Create wildcard <code>${branchName}</code>`);
    }

    this.$dropdownFooter.toggleClass('hidden', !branchName);
  }
}

class ProtectedBranchDropdowns {
  constructor(options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchDropdown({
        $dropdown: $(el),
        onSelect: onSelect
      });
    });
  }
 }
