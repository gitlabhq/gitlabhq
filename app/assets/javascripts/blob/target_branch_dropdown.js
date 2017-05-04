/* eslint-disable class-methods-use-this */
const SELECT_ITEM_MSG = 'Select';

class TargetBranchDropDown {
  constructor(dropdown) {
    this.dropdown = dropdown;
    this.$dropdown = $(dropdown);
    this.fieldName = this.dropdown.getAttribute('data-field-name');
    this.form = this.dropdown.closest('form');
    this.createDropdown();
  }

  static bootstrap() {
    const dropdowns = document.querySelectorAll('.js-project-branches-dropdown');
    [].forEach.call(dropdowns, dropdown => new TargetBranchDropDown(dropdown));
  }

  createDropdown() {
    const self = this;
    this.$dropdown.glDropdown({
      selectable: true,
      filterable: true,
      search: {
        fields: ['title'],
      },
      data: (term, callback) => $.ajax({
        url: self.dropdown.getAttribute('data-refs-url'),
        data: {
          ref: self.dropdown.getAttribute('data-ref'),
          show_all: true,
        },
        dataType: 'json',
      }).done(refs => callback(self.dropdownData(refs))),
      toggleLabel(item, el) {
        if (el.is('.is-active')) {
          return item.text;
        }
        return SELECT_ITEM_MSG;
      },
      clicked(options) {
        options.e.preventDefault();
        self.onClick.call(self);
      },
      fieldName: self.fieldName,
    });
    return new gl.CreateBranchDropdown(this.form.querySelector('.dropdown-new-branch'), this);
  }

  onClick() {
    this.enableSubmit();
    this.$dropdown.trigger('change.branch');
  }

  enableSubmit() {
    const submitBtn = this.form.querySelector('[type="submit"]');
    if (this.branchInput && this.branchInput.value) {
      submitBtn.removeAttribute('disabled');
    } else {
      submitBtn.setAttribute('disabled', '');
    }
  }

  dropdownData(refs) {
    const branchList = this.dropdownItems(refs);
    this.cachedRefs = refs;
    this.addDefaultBranch(branchList);
    this.addNewBranch(branchList);
    return { Branches: branchList };
  }

  dropdownItems(refs) {
    return refs.map(this.dropdownItem);
  }

  dropdownItem(ref) {
    return { id: ref, text: ref, title: ref };
  }

  addDefaultBranch(branchList) {
    // when no branch is selected do nothing
    if (!this.branchInput) {
      return;
    }

    const branchInputVal = this.branchInput.value;
    const currentBranchIndex = this.searchBranch(branchList, branchInputVal);

    if (currentBranchIndex === -1) {
      this.unshiftBranch(branchList, this.dropdownItem(branchInputVal));
    }
  }

  addNewBranch(branchList) {
    if (this.newBranch) {
      this.unshiftBranch(branchList, this.newBranch);
    }
  }

  searchBranch(branchList, branchName) {
    return _.findIndex(branchList, el => branchName === el.id);
  }

  unshiftBranch(branchList, branch) {
    const branchIndex = this.searchBranch(branchList, branch.id);

    if (branchIndex === -1) {
      branchList.unshift(branch);
    }
  }

  setNewBranch(newBranchName) {
    this.newBranch = this.dropdownItem(newBranchName);
    this.refreshData();
    this.selectBranch(this.searchBranch(this.glDropdown.fullData.Branches, newBranchName));
  }

  refreshData() {
    this.glDropdown.fullData = this.dropdownData(this.cachedRefs);
    this.clearFilter();
  }

  clearFilter() {
    // apply an empty filter in order to refresh the data
    this.glDropdown.filter.filter('');
    this.dropdown.closest('.dropdown').querySelector('.dropdown-page-one .dropdown-input-field').value = '';
  }

  selectBranch(index) {
    const branch = this.dropdown.closest('.dropdown').querySelectorAll('li a')[index];

    if (!branch.classList.contains('is-active')) {
      branch.click();
    } else {
      this.closeDropdown();
    }
  }

  closeDropdown() {
    this.dropdown.closest('.dropdown').querySelector('.dropdown-menu-close').click();
  }

  get branchInput() {
    return this.form.querySelector(`input[name="${this.fieldName}"]`);
  }

  get glDropdown() {
    return this.$dropdown.data('glDropdown');
  }
}

window.gl = window.gl || {};
gl.TargetBranchDropDown = TargetBranchDropDown;
