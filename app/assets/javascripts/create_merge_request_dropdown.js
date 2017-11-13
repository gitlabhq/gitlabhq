/* eslint-disable no-new */
import Flash from './flash';
import DropLab from './droplab/drop_lab';
import ISetter from './droplab/plugins/input_setter';

// Todo: Remove this when fixing issue in input_setter plugin
const InputSetter = Object.assign({}, ISetter);

const CREATE_MERGE_REQUEST = 'create-mr';
const CREATE_BRANCH = 'create-branch';

export default class CreateMergeRequestDropdown {
  constructor(wrapperEl) {
    this.wrapperEl = wrapperEl;
    this.createMergeRequestButton = this.wrapperEl.querySelector('.js-create-merge-request');
    this.dropdownToggle = this.wrapperEl.querySelector('.js-dropdown-toggle');
    this.dropdownList = this.wrapperEl.querySelector('.dropdown-menu');
    this.availableButton = this.wrapperEl.querySelector('.available');
    this.unavailableButton = this.wrapperEl.querySelector('.unavailable');
    this.unavailableButtonArrow = this.unavailableButton.querySelector('.fa');
    this.unavailableButtonText = this.unavailableButton.querySelector('.text');

    this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
    this.canCreatePath = this.wrapperEl.dataset.canCreatePath;
    this.createMrPath = this.wrapperEl.dataset.createMrPath;
    this.droplabInitialized = false;
    this.isCreatingMergeRequest = false;
    this.mergeRequestCreated = false;
    this.isCreatingBranch = false;
    this.branchCreated = false;

    this.init();
  }

  init() {
    this.checkAbilityToCreateBranch();
  }

  available() {
    this.availableButton.classList.remove('hide');
    this.unavailableButton.classList.add('hide');
  }

  unavailable() {
    this.availableButton.classList.add('hide');
    this.unavailableButton.classList.remove('hide');
  }

  enable() {
    this.createMergeRequestButton.classList.remove('disabled');
    this.createMergeRequestButton.removeAttribute('disabled');

    this.dropdownToggle.classList.remove('disabled');
    this.dropdownToggle.removeAttribute('disabled');
  }

  disable() {
    this.createMergeRequestButton.classList.add('disabled');
    this.createMergeRequestButton.setAttribute('disabled', 'disabled');

    this.dropdownToggle.classList.add('disabled');
    this.dropdownToggle.setAttribute('disabled', 'disabled');
  }

  hide() {
    this.wrapperEl.classList.add('hide');
  }

  setUnavailableButtonState(isLoading = true) {
    if (isLoading) {
      this.unavailableButtonArrow.classList.add('fa-spinner', 'fa-spin');
      this.unavailableButtonArrow.classList.remove('fa-exclamation-triangle');
      this.unavailableButtonText.textContent = 'Checking branch availability…';
    } else {
      this.unavailableButtonArrow.classList.remove('fa-spinner', 'fa-spin');
      this.unavailableButtonArrow.classList.add('fa-exclamation-triangle');
      this.unavailableButtonText.textContent = 'New branch unavailable';
    }
  }

  checkAbilityToCreateBranch() {
    return $.ajax({
      type: 'GET',
      dataType: 'json',
      url: this.canCreatePath,
      beforeSend: () => this.setUnavailableButtonState(),
    })
    .done((data) => {
      this.setUnavailableButtonState(false);

      if (data.can_create_branch) {
        this.available();
        this.enable();

        if (!this.droplabInitialized) {
          this.droplabInitialized = true;
          this.initDroplab();
          this.bindEvents();
        }
      } else if (data.has_related_branch) {
        this.hide();
      }
    }).fail(() => {
      this.unavailable();
      this.disable();
      new Flash('Failed to check if a new branch can be created.');
    });
  }

  initDroplab() {
    this.droplab = new DropLab();

    this.droplab.init(this.dropdownToggle, this.dropdownList, [InputSetter],
      this.getDroplabConfig());
  }

  getDroplabConfig() {
    return {
      InputSetter: [{
        input: this.createMergeRequestButton,
        valueAttribute: 'data-value',
        inputAttribute: 'data-action',
      }, {
        input: this.createMergeRequestButton,
        valueAttribute: 'data-text',
      }],
    };
  }

  bindEvents() {
    this.createMergeRequestButton
      .addEventListener('click', this.onClickCreateMergeRequestButton.bind(this));
  }

  isBusy() {
    return this.isCreatingMergeRequest ||
      this.mergeRequestCreated ||
      this.isCreatingBranch ||
      this.branchCreated;
  }

  onClickCreateMergeRequestButton(e) {
    let xhr = null;
    e.preventDefault();

    if (this.isBusy()) {
      return;
    }

    if (e.target.dataset.action === CREATE_MERGE_REQUEST) {
      xhr = this.createMergeRequest();
    } else if (e.target.dataset.action === CREATE_BRANCH) {
      xhr = this.createBranch();
    }

    xhr.fail(() => {
      this.isCreatingMergeRequest = false;
      this.isCreatingBranch = false;
    });

    xhr.always(() => this.enable());

    this.disable();
  }

  createMergeRequest() {
    return $.ajax({
      method: 'POST',
      dataType: 'json',
      url: this.createMrPath,
      beforeSend: () => (this.isCreatingMergeRequest = true),
    })
    .done((data) => {
      this.mergeRequestCreated = true;
      window.location.href = data.url;
    })
    .fail(() => new Flash('Failed to create Merge Request. Please try again.'));
  }

  createBranch() {
    return $.ajax({
      method: 'POST',
      dataType: 'json',
      url: this.createBranchPath,
      beforeSend: () => (this.isCreatingBranch = true),
    })
    .done((data) => {
      this.branchCreated = true;
      window.location.href = data.url;
    })
    .fail(() => new Flash('Failed to create a branch for this issue. Please try again.'));
  }
}
