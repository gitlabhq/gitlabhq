class CreateBranchDropdown {
  constructor(el, targetBranchDropdown) {
    this.targetBranchDropdown = targetBranchDropdown;
    this.el = el;
    this.dropdownBack = this.el.closest('.dropdown').querySelector('.dropdown-menu-back');
    this.cancelButton = this.el.querySelector('.js-cancel-branch-btn');
    this.newBranchField = this.el.querySelector('#new_branch_name');
    this.newBranchCreateButton = this.el.querySelector('.js-new-branch-btn');

    this.newBranchCreateButton.setAttribute('disabled', '');

    this.addBindings();
    this.cleanupWrapper = this.cleanup.bind(this);
    document.addEventListener('beforeunload', this.cleanupWrapper);
  }

  cleanup() {
    this.cleanBindings();
    document.removeEventListener('beforeunload', this.cleanupWrapper);
  }

  cleanBindings() {
    this.newBranchField.removeEventListener('keyup', this.enableBranchCreateButtonWrapper);
    this.newBranchField.removeEventListener('change', this.enableBranchCreateButtonWrapper);
    this.newBranchField.removeEventListener('keydown', this.handleNewBranchKeydownWrapper);
    this.dropdownBack.removeEventListener('click', this.resetFormWrapper);
    this.cancelButton.removeEventListener('click', this.handleCancelClickWrapper);
    this.newBranchCreateButton.removeEventListener('click', this.createBranchWrapper);
  }

  addBindings() {
    this.enableBranchCreateButtonWrapper = this.enableBranchCreateButton.bind(this);
    this.handleNewBranchKeydownWrapper = this.handleNewBranchKeydown.bind(this);
    this.resetFormWrapper = this.resetForm.bind(this);
    this.handleCancelClickWrapper = this.handleCancelClick.bind(this);
    this.createBranchWrapper = this.createBranch.bind(this);

    this.newBranchField.addEventListener('keyup', this.enableBranchCreateButtonWrapper);
    this.newBranchField.addEventListener('change', this.enableBranchCreateButtonWrapper);
    this.newBranchField.addEventListener('keydown', this.handleNewBranchKeydownWrapper);
    this.dropdownBack.addEventListener('click', this.resetFormWrapper);
    this.cancelButton.addEventListener('click', this.handleCancelClickWrapper);
    this.newBranchCreateButton.addEventListener('click', this.createBranchWrapper);
  }

  handleCancelClick(e) {
    e.preventDefault();
    e.stopPropagation();

    this.resetForm();
    this.dropdownBack.click();
  }

  handleNewBranchKeydown(e) {
    const keyCode = e.which;
    const ENTER_KEYCODE = 13;
    if (keyCode === ENTER_KEYCODE) {
      this.createBranch(e);
    }
  }

  enableBranchCreateButton() {
    if (this.newBranchField.value !== '') {
      this.newBranchCreateButton.removeAttribute('disabled');
    } else {
      this.newBranchCreateButton.setAttribute('disabled', '');
    }
  }

  resetForm() {
    this.newBranchField.value = '';
    this.enableBranchCreateButtonWrapper();
  }

  createBranch(e) {
    e.preventDefault();

    if (this.newBranchCreateButton.getAttribute('disabled') === '') {
      return;
    }
    const newBranchName = this.newBranchField.value;
    this.targetBranchDropdown.setNewBranch(newBranchName);
    this.resetForm();
  }
}

window.gl = window.gl || {};
gl.CreateBranchDropdown = CreateBranchDropdown;
