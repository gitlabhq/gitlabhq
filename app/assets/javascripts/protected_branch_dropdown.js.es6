(global => {
  global.gl = global.gl || {};

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
        text(protectedBranch) {
          return _.escape(protectedBranch.title);
        },
        id(protectedBranch) {
          return _.escape(protectedBranch.id);
        },
        onFilter: this.toggleCreateNewButton.bind(this),
        clicked: (item, $el, e) => {
          e.preventDefault();
          this.onSelect();
        }
      });
    }

    onClickCreateWildcard() {
      // Refresh the dropdown's data, which ends up calling `getProtectedBranches`
      this.$dropdown.data('glDropdown').remote.execute();
      this.$dropdown.data('glDropdown').selectRowAtIndex(0);
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
          .find('.create-new-protected-branch code')
          .text(branchName);
      }

      this.$dropdownFooter.toggleClass('hidden', !branchName);
    }
  }

  global.gl.ProtectedBranchDropdown = ProtectedBranchDropdown;
})(window);
