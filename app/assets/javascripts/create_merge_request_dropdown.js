/* eslint-disable no-new */
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import Flash from './flash';
import DropLab from './droplab/drop_lab';
import ISetter from './droplab/plugins/input_setter';
import { __, sprintf } from './locale';
import {
  init as initConfidentialMergeRequest,
  isConfidentialIssue,
  canCreateConfidentialMergeRequest,
} from './confidential_merge_request';
import confidentialMergeRequestState from './confidential_merge_request/state';

// Todo: Remove this when fixing issue in input_setter plugin
const InputSetter = Object.assign({}, ISetter);

const CREATE_MERGE_REQUEST = 'create-mr';
const CREATE_BRANCH = 'create-branch';

function createEndpoint(projectPath, endpoint) {
  if (canCreateConfidentialMergeRequest()) {
    return endpoint.replace(
      projectPath,
      confidentialMergeRequestState.selectedProject.pathWithNamespace,
    );
  }

  return endpoint;
}

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
    this.refInput = this.wrapperEl.querySelector('.js-ref');
    this.refMessage = this.wrapperEl.querySelector('.js-ref-message');
    this.unavailableButton = this.wrapperEl.querySelector('.unavailable');
    this.unavailableButtonArrow = this.unavailableButton.querySelector('.fa');
    this.unavailableButtonText = this.unavailableButton.querySelector('.text');

    this.branchCreated = false;
    this.branchIsValid = true;
    this.canCreatePath = this.wrapperEl.dataset.canCreatePath;
    this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
    this.createMrPath = this.wrapperEl.dataset.createMrPath;
    this.droplabInitialized = false;
    this.isCreatingBranch = false;
    this.isCreatingMergeRequest = false;
    this.isGettingRef = false;
    this.mergeRequestCreated = false;
    this.refDebounce = _.debounce((value, target) => this.getRef(value, target), 500);
    this.refIsValid = true;
    this.refsPath = this.wrapperEl.dataset.refsPath;
    this.suggestedRef = this.refInput.value;
    this.projectPath = this.wrapperEl.dataset.projectPath;
    this.projectId = this.wrapperEl.dataset.projectId;

    // These regexps are used to replace
    // a backend generated new branch name and its source (ref)
    // with user's inputs.
    this.regexps = {
      branch: {
        createBranchPath: new RegExp('(branch_name=)(.+?)(?=&issue)'),
        createMrPath: new RegExp('(branch_name=)(.+?)(?=&ref)'),
      },
      ref: {
        createBranchPath: new RegExp('(ref=)(.+?)$'),
        createMrPath: new RegExp('(ref=)(.+?)$'),
      },
    };

    this.init();

    if (isConfidentialIssue()) {
      this.createMergeRequestButton.setAttribute(
        'data-dropdown-trigger',
        '#create-merge-request-dropdown',
      );
      initConfidentialMergeRequest();
    }
  }

  available() {
    this.availableButton.classList.remove('hidden');
    this.unavailableButton.classList.add('hidden');
  }

  bindEvents() {
    this.createMergeRequestButton.addEventListener(
      'click',
      this.onClickCreateMergeRequestButton.bind(this),
    );
    this.createTargetButton.addEventListener(
      'click',
      this.onClickCreateMergeRequestButton.bind(this),
    );
    this.branchInput.addEventListener('keyup', this.onChangeInput.bind(this));
    this.dropdownToggle.addEventListener('click', this.onClickSetFocusOnBranchNameInput.bind(this));
    this.refInput.addEventListener('keyup', this.onChangeInput.bind(this));
    this.refInput.addEventListener('keydown', CreateMergeRequestDropdown.processTab.bind(this));
  }

  checkAbilityToCreateBranch() {
    this.setUnavailableButtonState();

    axios
      .get(this.canCreatePath)
      .then(({ data }) => {
        this.setUnavailableButtonState(false);

        if (data.can_create_branch) {
          this.available();
          this.enable();
          this.updateBranchName(data.suggested_branch_name);

          if (!this.droplabInitialized) {
            this.droplabInitialized = true;
            this.initDroplab();
            this.bindEvents();
          }
        } else {
          this.hide();
        }
      })
      .catch(() => {
        this.unavailable();
        this.disable();
        Flash(__('Failed to check related branches.'));
      });
  }

  createBranch() {
    this.isCreatingBranch = true;

    return axios
      .post(createEndpoint(this.projectPath, this.createBranchPath), {
        confidential_issue_project_id: canCreateConfidentialMergeRequest() ? this.projectId : null,
      })
      .then(({ data }) => {
        this.branchCreated = true;
        window.location.href = data.url;
      })
      .catch(() => Flash(__('Failed to create a branch for this issue. Please try again.')));
  }

  createMergeRequest() {
    this.isCreatingMergeRequest = true;

    return axios
      .post(this.createMrPath, {
        target_project_id: canCreateConfidentialMergeRequest()
          ? confidentialMergeRequestState.selectedProject.id
          : null,
      })
      .then(({ data }) => {
        this.mergeRequestCreated = true;
        window.location.href = data.url;
      })
      .catch(() => Flash(__('Failed to create Merge Request. Please try again.')));
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

  enable() {
    if (isConfidentialIssue() && !canCreateConfidentialMergeRequest()) return;

    this.createMergeRequestButton.classList.remove('disabled');
    this.createMergeRequestButton.removeAttribute('disabled');

    this.createTargetButton.classList.remove('disabled');
    this.createTargetButton.removeAttribute('disabled');

    this.dropdownToggle.classList.remove('disabled');
    this.dropdownToggle.removeAttribute('disabled');
  }

  static findByValue(objects, ref, returnFirstMatch = false) {
    if (!objects || !objects.length) return false;
    if (objects.indexOf(ref) > -1) return ref;
    if (returnFirstMatch) return objects.find(item => new RegExp(`^${ref}`).test(item));

    return false;
  }

  getDroplabConfig() {
    return {
      addActiveClassToDropdownButton: true,
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
      hideOnClick: false,
    };
  }

  static getInputSelectedText(input) {
    const start = input.selectionStart;
    const end = input.selectionEnd;

    return input.value.substr(start, end - start);
  }

  getRef(ref, target = 'all') {
    if (!ref) return false;

    return axios
      .get(`${createEndpoint(this.projectPath, this.refsPath)}${encodeURIComponent(ref)}`)
      .then(({ data }) => {
        const branches = data[Object.keys(data)[0]];
        const tags = data[Object.keys(data)[1]];
        let result;

        if (target === 'branch') {
          result = CreateMergeRequestDropdown.findByValue(branches, ref);
        } else {
          result =
            CreateMergeRequestDropdown.findByValue(branches, ref, true) ||
            CreateMergeRequestDropdown.findByValue(tags, ref, true);
          this.suggestedRef = result;
        }

        this.isGettingRef = false;

        return this.updateInputState(target, ref, result);
      })
      .catch(() => {
        this.unavailable();
        this.disable();
        new Flash(__('Failed to get ref.'));

        this.isGettingRef = false;

        return false;
      });
  }

  getTargetData(target) {
    return {
      input: this[`${target}Input`],
      message: this[`${target}Message`],
    };
  }

  hide() {
    this.wrapperEl.classList.add('hidden');
  }

  init() {
    this.checkAbilityToCreateBranch();
  }

  initDroplab() {
    this.droplab = new DropLab();

    this.droplab.init(
      this.dropdownToggle,
      this.dropdownList,
      [InputSetter],
      this.getDroplabConfig(),
    );
  }

  inputsAreValid() {
    return this.branchIsValid && this.refIsValid;
  }

  isBusy() {
    return (
      this.isCreatingMergeRequest ||
      this.mergeRequestCreated ||
      this.isCreatingBranch ||
      this.branchCreated ||
      this.isGettingRef
    );
  }

  onChangeInput(event) {
    this.disable();
    let target;
    let value;

    if (event.target === this.branchInput) {
      target = 'branch';
      ({ value } = this.branchInput);
    } else if (event.target === this.refInput) {
      target = 'ref';
      value =
        event.target.value.slice(0, event.target.selectionStart) +
        event.target.value.slice(event.target.selectionEnd);
    } else {
      return false;
    }

    if (this.isGettingRef) return false;

    // `ENTER` key submits the data.
    if (event.keyCode === 13 && this.inputsAreValid()) {
      event.preventDefault();
      return this.createMergeRequestButton.click();
    }

    // If the input is empty, use the original value generated by the backend.
    if (!value) {
      this.createBranchPath = this.wrapperEl.dataset.createBranchPath;
      this.createMrPath = this.wrapperEl.dataset.createMrPath;

      if (target === 'branch') {
        this.branchIsValid = true;
      } else {
        this.refIsValid = true;
      }

      this.enable();
      this.showAvailableMessage(target);
      return true;
    }

    this.showCheckingMessage(target);
    this.refDebounce(value, target);

    return true;
  }

  onClickCreateMergeRequestButton(event) {
    let xhr = null;
    event.preventDefault();

    if (isConfidentialIssue() && !event.target.classList.contains('js-create-target')) {
      this.droplab.hooks.forEach(hook => hook.list.toggle());

      return;
    }

    if (this.isBusy()) {
      return;
    }

    if (event.target.dataset.action === CREATE_MERGE_REQUEST) {
      xhr = this.createMergeRequest();
    } else if (event.target.dataset.action === CREATE_BRANCH) {
      xhr = this.createBranch();
    }

    xhr.catch(() => {
      this.isCreatingMergeRequest = false;
      this.isCreatingBranch = false;

      this.enable();
    });

    this.disable();
  }

  onClickSetFocusOnBranchNameInput() {
    this.branchInput.focus();
  }

  // `TAB` autocompletes the source.
  static processTab(event) {
    if (event.keyCode !== 9 || this.isGettingRef) return;

    const selectedText = CreateMergeRequestDropdown.getInputSelectedText(this.refInput);

    // if nothing selected, we don't need to autocomplete anything. Do the default TAB action.
    // If a user manually selected text, don't autocomplete anything. Do the default TAB action.
    if (!selectedText || this.refInput.dataset.value === this.suggestedRef) return;

    event.preventDefault();
    window.getSelection().removeAllRanges();
  }

  removeMessage(target) {
    const { input, message } = this.getTargetData(target);
    const inputClasses = ['gl-field-error-outline', 'gl-field-success-outline'];
    const messageClasses = ['text-muted', 'text-danger', 'text-success'];

    inputClasses.forEach(cssClass => input.classList.remove(cssClass));
    messageClasses.forEach(cssClass => message.classList.remove(cssClass));
    message.style.display = 'none';
  }

  setUnavailableButtonState(isLoading = true) {
    if (isLoading) {
      this.unavailableButtonArrow.classList.add('fa-spin');
      this.unavailableButtonArrow.classList.add('fa-spinner');
      this.unavailableButtonArrow.classList.remove('fa-exclamation-triangle');
      this.unavailableButtonText.textContent = __('Checking branch availability...');
    } else {
      this.unavailableButtonArrow.classList.remove('fa-spin');
      this.unavailableButtonArrow.classList.remove('fa-spinner');
      this.unavailableButtonArrow.classList.add('fa-exclamation-triangle');
      this.unavailableButtonText.textContent = __('New branch unavailable');
    }
  }

  showAvailableMessage(target) {
    const { input, message } = this.getTargetData(target);
    const text = target === 'branch' ? __('Branch name') : __('Source');

    this.removeMessage(target);
    input.classList.add('gl-field-success-outline');
    message.classList.add('text-success');
    message.textContent = sprintf(__('%{text} is available'), { text });
    message.style.display = 'inline-block';
  }

  showCheckingMessage(target) {
    const { message } = this.getTargetData(target);
    const text = target === 'branch' ? __('branch name') : __('source');

    this.removeMessage(target);
    message.classList.add('text-muted');
    message.textContent = sprintf(__('Checking %{text} availability…'), { text });
    message.style.display = 'inline-block';
  }

  showNotAvailableMessage(target) {
    const { input, message } = this.getTargetData(target);
    const text =
      target === 'branch' ? __('Branch is already taken') : __('Source is not available');

    this.removeMessage(target);
    input.classList.add('gl-field-error-outline');
    message.classList.add('text-danger');
    message.textContent = text;
    message.style.display = 'inline-block';
  }

  unavailable() {
    this.availableButton.classList.add('hidden');
    this.unavailableButton.classList.remove('hidden');
  }

  updateBranchName(suggestedBranchName) {
    this.branchInput.value = suggestedBranchName;
    this.updateCreatePaths('branch', suggestedBranchName);
  }

  updateInputState(target, ref, result) {
    // target - 'branch' or 'ref' - which the input field we are searching a ref for.
    // ref - string - what a user typed.
    // result - string - what has been found on backend.

    // If a found branch equals exact the same text a user typed,
    // that means a new branch cannot be created as it already exists.
    if (ref === result) {
      if (target === 'branch') {
        this.branchIsValid = false;
        this.showNotAvailableMessage('branch');
      } else {
        this.refIsValid = true;
        this.refInput.dataset.value = ref;
        this.showAvailableMessage('ref');
        this.updateCreatePaths(target, ref);
      }
    } else if (target === 'branch') {
      this.branchIsValid = true;
      this.showAvailableMessage('branch');
      this.updateCreatePaths(target, ref);
    } else {
      this.refIsValid = false;
      this.refInput.dataset.value = ref;
      this.disableCreateAction();
      this.showNotAvailableMessage('ref');

      // Show ref hint.
      if (result) {
        this.refInput.value = result;
        this.refInput.setSelectionRange(ref.length, result.length);
      }
    }

    if (this.inputsAreValid()) {
      this.enable();
    } else {
      this.disableCreateAction();
    }
  }

  // target - 'branch' or 'ref'
  // ref - string - the new value to use as branch or ref
  updateCreatePaths(target, ref) {
    const pathReplacement = `$1${encodeURIComponent(ref)}`;

    this.createBranchPath = this.createBranchPath.replace(
      this.regexps[target].createBranchPath,
      pathReplacement,
    );
    this.createMrPath = this.createMrPath.replace(
      this.regexps[target].createMrPath,
      pathReplacement,
    );
  }
}
