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
    this.availableButton = this.wrapperEl.querySelector('.available');
    this.branchInput = this.wrapperEl.querySelector('.js-branch-name');
    this.branchMessage = this.wrapperEl.querySelector('.js-branch-message');
    this.createMergeRequestButton = this.wrapperEl.querySelector('.js-create-merge-request');
    this.createTargetButton = this.wrapperEl.querySelector('.js-create-target');
    this.dropdownList = this.wrapperEl.querySelector('.dropdown-menu');
    this.dropdownToggle = this.wrapperEl.querySelector('.js-dropdown-toggle');
    this.refInput = this.wrapperEl.querySelector('.ref');
    this.refMessage = this.wrapperEl.querySelector('.ref-message');
    this.unavailableButton = this.wrapperEl.querySelector('.unavailable');
    this.unavailableButtonArrow = this.unavailableButton.querySelector('.fa');
    this.unavailableButtonText = this.unavailableButton.querySelector('.text');

    this.branchCreated = false;
    this.branchTaken = true;
    this.canCreatePath = this.wrapperEl.dataset.canCreatePath;
    this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
    this.createMrPath = this.wrapperEl.dataset.createMrPath;
    this.droplabInitialized = false;
    this.getRefsPath = this.wrapperEl.dataset.getRefsPath;
    this.isCreatingBranch = false;
    this.isCreatingMergeRequest = false;
    this.isGettingRefs = false;
    this.inputsAreValid = true;
    this.mergeRequestCreated = false;
    this.delay = null;
    this.refs = {};

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

    this.createTargetButton.classList.remove('disabled');
    this.createTargetButton.removeAttribute('disabled', 'disabled');

    this.dropdownToggle.classList.remove('disabled');
    this.dropdownToggle.removeAttribute('disabled');
  }

  disable() {
    this.disableCreateAction();

    this.dropdownToggle.classList.add('disabled');
    this.dropdownToggle.setAttribute('disabled', 'disabled');
  }

  disableCreateAction() {
    this.createMergeRequestButton.classList.add('disabled');
    this.createMergeRequestButton.setAttribute('disabled', 'disabled');

    this.createTargetButton.classList.add('disabled');
    this.createTargetButton.setAttribute('disabled', 'disabled');
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

  getRefs() {
    return $.ajax({
      method: 'GET',
      dataType: 'json',
      url: this.getRefsPath,
      beforeSend: () => {
        this.isGettingRefs = true;
      },
    })
    .always(() => {
      this.isGettingRefs = false;
    })
    .done((data) => {
      this.refs = data;
    })
    .fail(() => {
      this.unavailable();
      this.disable();
      new Flash('Failed to get refs.');
    });
  }

  getRef(ref, type = 'all') {
    if (!this.refs) return false;

    const target = new RegExp(`^${$.trim(ref).replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')}`);

    if (type === 'branch') return this.refs.Branches.find(value => target.test(value));

    return this.refs.Branches.find(value => target.test(value)) ||
      this.refs.Tags.find(value => target.test(value));
  }

  initDroplab() {
    this.droplab = new DropLab();

    this.droplab.init(this.dropdownToggle, this.dropdownList, [InputSetter],
      this.getDroplabConfig());
  }

  getDroplabConfig() {
    return {
      InputSetter: [
        {
          input: this.createMergeRequestButton,
          valueAttribute: 'data-value',
          inputAttribute: 'data-action',
        },
        {
          input: this.createMergeRequestButton,
          valueAttribute: 'data-text',
        },
        {
          input: this.createTargetButton,
          valueAttribute: 'data-value',
          inputAttribute: 'data-action',
        },
        {
          input: this.createTargetButton,
          valueAttribute: 'data-text',
        },
      ],
    };
  }

  bindEvents() {
    this.createMergeRequestButton.addEventListener('click', this.onClickCreateMergeRequestButton.bind(this));
    this.createTargetButton.addEventListener('click', this.onClickCreateMergeRequestButton.bind(this));
    this.dropdownToggle.addEventListener('click', this.onClickSetFocusOnBranchNameInput.bind(this));
    this.dropdownToggle.addEventListener('click', this.onClickGetRefs.bind(this));
    this.branchInput.addEventListener('keyup', this.onChangeBranchInput.bind(this));
    this.refInput.addEventListener('keyup', this.onChangeRefInput.bind(this));
    this.refInput.addEventListener('keydown', this.processTab.bind(this));
  }

  isBusy() {
    return this.isCreatingMergeRequest ||
      this.mergeRequestCreated ||
      this.isCreatingBranch ||
      this.branchCreated ||
      this.isGettingRefs;
  }

  // target: 'branch', 'ref'
  // type: 'checking', 'available', 'not_available'
  showMessage(target, type) {
    let input;
    let message;
    let text;

    if (target === 'branch') {
      input = this.branchInput;
      message = this.branchMessage;
      text = 'branch name';
    } else {
      input = this.refInput;
      message = this.refMessage;
      text = 'source';
    }

    // Remove gl-field error classes
    input.classList.remove('gl-field-error-outline');
    input.classList.remove('gl-field-success-outline');
    message.classList.remove('gl-field-hint');
    message.classList.remove('gl-field-error-message');
    message.classList.remove('gl-field-success-message');

    if (type === 'checking') {
      message.classList.add('gl-field-hint');
      message.textContent = `Checking ${text} availability...`;
      message.classList.remove('hide');

      return;
    }

    if (type === 'not_available') {
      if (target === 'branch') {
        text = 'Branch is already taken';
      } else {
        text = 'Source is not available';
      }

      input.classList.add('gl-field-error-outline');
      message.classList.add('gl-field-error-message');
      message.textContent = text;
      message.classList.remove('hide');

      return;
    }

    if (type === 'available') {
      text = text.charAt(0).toUpperCase() + text.slice(1);

      input.classList.add('gl-field-success-outline');
      message.classList.add('gl-field-success-message');
      message.textContent = `${text} is available`;
      message.classList.remove('hide');
    }
  }

  onClickSetFocusOnBranchNameInput() {
    this.branchInput.focus();
  }

  onClickGetRefs() {
    this.getRefs();
  }

  onChangeBranchInput(event) {
    const branch = this.branchInput.value;

    if (this.isGettingRefs) return;

    // `ENTER` key submits the data.
    if (event.keyCode === 13 && this.inputsAreValid) {
      this.createMergeRequestButton.click();
      return;
    }

    // `ESC` key closes the dropdown.
    if (event.keyCode === 27) {
      this.dropdownToggle.click();
      return;
    }

    // If the input is empty, use the original branch name generated by the backend.
    if (!branch) {
      this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
      this.createMrPath = this.wrapperEl.dataset.createMrPath;
      this.inputsAreValid = true;
      this.enable();
      this.showMessage('branch', 'available');
      return;
    }

    if (this.getRef(branch, 'branch') === branch) {
      this.inputsAreValid = false;
      this.disableCreateAction();
      this.showMessage('branch', 'not_available');
    } else {
      this.inputsAreValid = true;
      this.enable();
      this.showMessage('branch', 'available');
      this.createBranchPath = this.createBranchPath.replace(/(branch_name=)(.+?)(?=&issue)/, `$1${branch}`);
      this.createMrPath = this.createMrPath.replace(/(branch_name=)(.+?)(?=&ref)/, `$1${branch}`);
    }
  }

  onChangeRefInput(event) {
    // Remove selected text (autocomplete text).
    const ref = this.refInput.value.slice(0, this.refInput.selectionStart) +
      this.refInput.value.slice(this.refInput.selectionEnd);

    if (this.isGettingRefs) return;

    // `ENTER` key submits the data.
    if (event.keyCode === 13 && this.inputsAreValid) {
      this.createMergeRequestButton.click();
      return;
    }

    // `ESC` key closes the dropdown.
    if (event.keyCode === 27) {
      this.dropdownToggle.click();
      return;
    }

    // If the input is empty, use the original ref name generated by the backend.
    if (!ref) {
      this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
      this.createMrPath = this.wrapperEl.dataset.createMrPath;
      this.inputsAreValid = true;
      this.enable();
      this.showMessage('ref', 'available');
      return;
    }

    this.createBranchPath = this.createBranchPath.replace(/(ref=)(.+?)$/, `$1${ref}`);
    this.createMrPath = this.createMrPath.replace(/(ref=)(.+?)$/, `$1${ref}`);

    const foundRef = this.getRef(ref, 'all');

    if (ref === foundRef) {
      this.inputsAreValid = true;
      this.enable();
      this.showMessage('ref', 'available');
    } else {
      this.inputsAreValid = false;
      this.disableCreateAction();
      this.showMessage('ref', 'not_available');

      // Show the first found ref as a hint.
      if (foundRef) {
        clearTimeout(this.delay);
        this.delay = setTimeout(() => {
          this.refInput.value = foundRef;
          this.refInput.setSelectionRange(ref.length, foundRef.length);
        }, 500);
      }
    }
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

  // `TAB` autocompletes the source.
  processTab(event) {
    if (event.keyCode !== 9) return;

    const value = this.refInput.value;

    event.preventDefault();

    this.refInput.value = '';
    this.refInput.value = value;
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
