import { debounce } from 'lodash';
import {
  init as initConfidentialMergeRequest,
  isConfidentialIssue,
  canCreateConfidentialMergeRequest,
} from '~/confidential_merge_request';
import confidentialMergeRequestState from '~/confidential_merge_request/state';
import DropLab from '~/filtered_search/droplab/drop_lab_deprecated';
import ISetter from '~/filtered_search/droplab/plugins/input_setter';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  findInvalidBranchNameCharacters,
  humanizeBranchValidationErrors,
} from '~/lib/utils/text_utility';
import api from '~/api';

// Todo: Remove this when fixing issue in input_setter plugin
const InputSetter = { ...ISetter };

const CREATE_MERGE_REQUEST = 'create-mr';
const CREATE_BRANCH = 'create-branch';

const VALIDATION_TYPE_BRANCH_UNAVAILABLE = 'branch_unavailable';
const VALIDATION_TYPE_INVALID_CHARS = 'invalid_chars';

const INPUT_TARGET_PROJECT = 'project';
const INPUT_TARGET_BRANCH = 'branch';
const INPUT_TARGET_REF = 'ref';

function createEndpoint(projectPath, endpoint) {
  if (canCreateConfidentialMergeRequest()) {
    return endpoint.replace(
      projectPath,
      confidentialMergeRequestState.selectedProject.pathWithNamespace,
    );
  }

  return endpoint;
}

function getValidationError(target, inputValue, validationType) {
  const invalidChars = findInvalidBranchNameCharacters(inputValue.value);
  let text;

  if (invalidChars && validationType === VALIDATION_TYPE_INVALID_CHARS) {
    text = humanizeBranchValidationErrors(invalidChars);
  }

  if (validationType === VALIDATION_TYPE_BRANCH_UNAVAILABLE) {
    text =
      target === INPUT_TARGET_BRANCH
        ? __('Branch is already taken')
        : __('Source is not available');
  }

  return text;
}
export default class CreateMergeRequestDropdown {
  constructor(wrapperEl) {
    this.wrapperEl = wrapperEl;
    this.availableButton = this.wrapperEl.querySelector('.available');
    this.branchNameInput = this.wrapperEl.querySelector('.js-branch-name');
    this.branchMessage = this.wrapperEl.querySelector('.js-branch-message');
    this.targetProjectInput = this.wrapperEl.querySelector('.js-target-project');
    this.createMergeRequestButton = this.wrapperEl.querySelector('.js-create-merge-request');
    this.createMergeRequestLoading = this.createMergeRequestButton.querySelector('.js-spinner');
    this.createTargetButton = this.wrapperEl.querySelector('.js-create-target');
    this.dropdownList = this.wrapperEl.querySelector('.dropdown-menu');
    this.dropdownToggle = this.wrapperEl.querySelector('.js-dropdown-toggle');
    this.sourceRefInput = this.wrapperEl.querySelector('.js-ref');
    this.refMessage = this.wrapperEl.querySelector('.js-ref-message');
    this.unavailableButton = this.wrapperEl.querySelector('.unavailable');
    this.unavailableButtonSpinner = this.unavailableButton.querySelector('.js-create-mr-spinner');
    this.unavailableButtonText = this.unavailableButton.querySelector('.text');

    this.isBranchCreationMode = false;
    this.branchCreated = false;
    this.branchIsValid = true;
    this.droplabInitialized = false;
    this.isCreatingBranch = false;
    this.isCreatingMergeRequest = false;
    this.refCancelToken = null;
    this.mergeRequestCreated = false;
    this.refDebounce = debounce((value, target) => this.getRef(value, target), 500);
    this.refIsValid = true;
    this.suggestedRef = this.refName;
    this.cancelSources = new Set();

    // These regexps are used to replace
    // a backend generated new branch name and its source (ref)
    // with user's inputs.
    this.regexps = {
      branch: {
        createBranchPath: /(branch_name=)(.+?)(?=&issue)/,
        createMrPath: /(source_branch%5D=)(.+?)(?=&)/,
      },
      ref: {
        createBranchPath: /(ref=)(.+?)$/,
        createMrPath: /(target_branch%5D=)(.+?)$/,
      },
    };

    this.init();

    if (isConfidentialIssue()) {
      this.createMergeRequestButton.dataset.dropdownTrigger = '#create-merge-request-dropdown';
      initConfidentialMergeRequest();
    }
  }

  get selectedProjectOption() {
    if (this.targetProjectInput) {
      return this.targetProjectInput.options[this.targetProjectInput.options.selectedIndex];
    }
    return null;
  }

  get sourceProject() {
    return {
      refsPath: this.wrapperEl.dataset.refsPath,
      projectPath: this.wrapperEl.dataset.projectPath,
      projectId: this.wrapperEl.dataset.projectId,
    };
  }

  get targetProject() {
    if (this.targetProjectInput) {
      const option = this.selectedProjectOption;
      return {
        refsPath: this.targetProjectInput.value,
        projectId: option.dataset.id,
        projectPath: option.dataset.fullPath,
      };
    }
    return this.sourceProject;
  }

  get branchName() {
    return this.branchNameInput.value || this.branchNameInput.placeholder;
  }

  get refName() {
    return this.sourceRefInput.value;
  }

  get canCreatePath() {
    return this.wrapperEl.dataset.canCreatePath;
  }

  get createBranchPath() {
    return this.wrapperEl.dataset.createBranchPath;
  }

  get createMrPath() {
    return this.selectedProjectOption?.dataset?.createMrPath || this.wrapperEl.dataset.createMrPath;
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
    this.branchNameInput.addEventListener('input', this.onBranchChange.bind(this));
    this.branchNameInput.addEventListener('keyup', this.onBranchChange.bind(this));
    if (this.targetProjectInput) {
      this.targetProjectInput.addEventListener('change', this.onTargetProjectChange.bind(this));
    }
    this.dropdownToggle.addEventListener('click', this.onClickSetFocusOnBranchNameInput.bind(this));
    // Detect for example when user pastes ref using the mouse
    this.sourceRefInput.addEventListener('input', this.onRefChange.bind(this));
    // Detect for example when user presses right arrow to apply the suggested ref
    this.sourceRefInput.addEventListener('keyup', this.onRefChange.bind(this));
    // Detect when user clicks inside the input to apply the suggested ref
    this.sourceRefInput.addEventListener('click', this.onRefChange.bind(this));
    // Detect when user presses tab to apply the suggested ref
    this.sourceRefInput.addEventListener(
      'keydown',
      CreateMergeRequestDropdown.processTab.bind(this),
    );
    Array.from(this.wrapperEl.querySelectorAll('.js-type-toggle')).forEach((el) => {
      el.addEventListener('click', this.toggleBranchCreationMode.bind(this));
    });
  }

  toggleBranchCreationMode(event) {
    if (event.currentTarget.dataset.value === 'create-branch') {
      this.disableProjectSelect();
      this.isBranchCreationMode = true;
    } else {
      this.enableProjectSelect();
      this.isBranchCreationMode = false;
    }
  }

  checkAbilityToCreateBranch() {
    this.setUnavailableButtonState();

    axios
      .get(this.canCreatePath)
      .then(({ data }) => {
        this.setUnavailableButtonState(false);

        if (!data.can_create_branch) {
          this.hide();
          return;
        }

        this.available();
        this.enable();
        this.updateBranchName(data.suggested_branch_name);

        if (!this.droplabInitialized) {
          this.droplabInitialized = true;
          this.initDroplab();
          this.bindEvents();
        }
      })
      .catch(() => {
        createAlert({
          message: __('Failed to check related branches.'),
        });
      });
  }

  createBranch(navigateToBranch = true) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (!this.refName) return Promise.reject(new Error('Missing ref name'));

    this.isCreatingBranch = true;

    const endpoint = createEndpoint(
      this.sourceProject.projectPath,
      mergeUrlParams({ ref: this.refName, branch_name: this.branchName }, this.createBranchPath),
    );

    return axios
      .post(endpoint, {
        confidential_issue_project_id: canCreateConfidentialMergeRequest()
          ? this.sourceProject.projectId
          : null,
      })
      .then(({ data }) => {
        this.branchCreated = true;

        if (navigateToBranch) {
          window.location.href = data.url;
        }
      })
      .catch(() =>
        createAlert({
          message: __('Failed to create a branch for this issue. Please try again.'),
        }),
      );
  }

  createMergeRequest() {
    this.isCreatingMergeRequest = true;

    return this.createBranch(false)
      .then(() => api.trackRedisHllUserEvent('i_code_review_user_create_mr_from_issue'))
      .then(() => {
        let path = canCreateConfidentialMergeRequest()
          ? this.createMrPath.replace(
              this.targetProject.projectPath,
              confidentialMergeRequestState.selectedProject.pathWithNamespace,
            )
          : this.createMrPath;
        path = mergeUrlParams(
          {
            'merge_request[target_branch]': this.refName,
            'merge_request[source_branch]': this.branchName,
          },
          path,
        );

        window.location.href = path;
      });
  }

  disable() {
    this.disableCreateAction();
  }

  setLoading(loading) {
    this.createMergeRequestLoading.classList.toggle('gl-display-none', !loading);
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
  }

  disableProjectSelect() {
    if (!this.targetProjectInput) return;
    this.targetProjectInput.classList.add('disabled');
    this.targetProjectInput.setAttribute('disabled', 'disabled');
  }

  enableProjectSelect() {
    if (!this.targetProjectInput) return;
    this.targetProjectInput.classList.remove('disabled');
    this.targetProjectInput.removeAttribute('disabled');
  }

  static findByValue(objects, ref, returnFirstMatch = false) {
    if (!objects || !objects.length) return false;
    if (objects.indexOf(ref) > -1) return ref;
    if (returnFirstMatch) return objects.find((item) => new RegExp(`^${ref}`).test(item));

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
    const source = axios.CancelToken.source();
    this.cancelSources.add(source);

    const project =
      target === INPUT_TARGET_REF && !this.isBranchCreationMode
        ? this.targetProject
        : this.sourceProject;

    return axios
      .get(`${createEndpoint(project.projectPath, project.refsPath)}${encodeURIComponent(ref)}`, {
        cancelToken: source.token,
      })
      .then(({ data }) => {
        const branches = data[Object.keys(data)[0]];
        const tags = data[Object.keys(data)[1]];
        let result;

        if (target === INPUT_TARGET_BRANCH) {
          result = CreateMergeRequestDropdown.findByValue(branches, ref);
        } else {
          result =
            CreateMergeRequestDropdown.findByValue(branches, ref, true) ||
            CreateMergeRequestDropdown.findByValue(tags, ref, true);
          this.suggestedRef = result;
        }

        this.updateInputState(target, ref, result);
      })
      .catch((thrown) => {
        if (axios.isCancel(thrown)) {
          return;
        }
        this.disable();
        createAlert({
          message: __('Failed to get ref.'),
        });
      })
      .finally(() => {
        this.cancelSources.delete(source);
      });
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
      this.branchCreated
    );
  }

  beforeChange() {
    // User changed input, cancel to prevent previous request from interfering
    if (this.cancelSources.size !== 0) {
      this.cancelSources.forEach((token) => {
        token.cancel();
        this.cancelSources.delete(token);
      });
    }
  }

  onTargetProjectChange() {
    this.beforeChange();
    this.getRef(this.refName, INPUT_TARGET_REF);
  }

  onBranchChange(event) {
    this.beforeChange();
    this.handleChange(event, INPUT_TARGET_BRANCH, this.branchName);
  }

  onRefChange(event) {
    this.beforeChange();

    const target = INPUT_TARGET_REF;

    if (event.target !== document.activeElement) {
      this.handleChange(event, target, event.target.value);
      return;
    }

    const value =
      event.target.value.slice(0, event.target.selectionStart) +
      event.target.value.slice(event.target.selectionEnd);

    this.handleChange(event, target, value);
  }

  handleChange(event, target, value) {
    // `ENTER` key submits the data.
    if (event.keyCode === 13 && this.inputsAreValid()) {
      event.preventDefault();
      this.createMergeRequestButton.click();
      return;
    }

    // If the input is empty, use the original value generated by the backend.
    if (!value) {
      if (target === INPUT_TARGET_BRANCH) {
        this.branchIsValid = true;
      } else {
        this.refIsValid = true;
      }

      this.enable();
      this.showAvailableMessage(target);
      this.refDebounce(value, target);
      return;
    }

    if (target !== INPUT_TARGET_PROJECT) this.showCheckingMessage(target);
    this.refDebounce(value, target);
  }

  onClickCreateMergeRequestButton(event) {
    event.preventDefault();

    if (this.cancelSources.size !== 0) return;

    if (isConfidentialIssue() && !event.currentTarget.classList.contains('js-create-target')) {
      this.droplab.hooks.forEach((hook) => hook.list.toggle());

      return;
    }

    if (this.isBusy()) {
      return;
    }

    let xhr = null;
    if (event.currentTarget.dataset.action === CREATE_MERGE_REQUEST) {
      xhr = this.createMergeRequest();
    } else if (event.currentTarget.dataset.action === CREATE_BRANCH) {
      xhr = this.createBranch();
    }

    xhr.catch(() => {
      this.isCreatingMergeRequest = false;
      this.isCreatingBranch = false;

      this.enable();
      this.setLoading(false);
    });

    this.setLoading(true);
    this.disable();
  }

  onClickSetFocusOnBranchNameInput() {
    this.branchNameInput.focus();
  }

  // `TAB` autocompletes the source.
  static processTab(event) {
    if (event.keyCode !== 9) return;

    const selectedText = CreateMergeRequestDropdown.getInputSelectedText(this.refInput);

    // if nothing selected, we don't need to autocomplete anything. Do the default TAB action.
    // If a user manually selected text, don't autocomplete anything. Do the default TAB action.
    if (!selectedText || this.refInput.dataset.value === this.suggestedRef) return;

    event.preventDefault();
    const caretPositionEnd = this.refInput.value.length;
    this.refInput.setSelectionRange(caretPositionEnd, caretPositionEnd);
  }

  getTargetData(target) {
    if (target === INPUT_TARGET_BRANCH) {
      return {
        input: this.branchNameInput,
        message: this.branchMessage,
      };
    }
    if (target === INPUT_TARGET_REF) {
      return {
        input: this.sourceRefInput,
        message: this.refMessage,
      };
    }
    return null;
  }

  removeMessage(target) {
    const { input, message } = this.getTargetData(target);
    const inputClasses = ['gl-field-error-outline', 'gl-field-success-outline'];
    const messageClasses = ['gl-text-gray-600', 'gl-text-red-500', 'gl-text-green-500'];

    inputClasses.forEach((cssClass) => input.classList.remove(cssClass));
    messageClasses.forEach((cssClass) => message.classList.remove(cssClass));
    message.style.display = 'none';
  }

  setUnavailableButtonState(isLoading = true) {
    if (isLoading) {
      this.unavailableButtonSpinner.classList.remove('gl-display-none');
      this.unavailableButtonText.textContent = __('Checking branch availability...');
    } else {
      this.unavailableButtonSpinner.classList.add('gl-display-none');
      this.unavailableButtonText.textContent = __('New branch unavailable');
    }
  }

  showAvailableMessage(target) {
    const { input, message } = this.getTargetData(target);
    const text = target === INPUT_TARGET_BRANCH ? __('Branch name') : __('Source');

    this.removeMessage(target);
    input.classList.add('gl-field-success-outline');
    message.classList.add('gl-text-green-500');
    message.textContent = sprintf(__('%{text} is available'), { text });
    message.style.display = 'inline-block';
  }

  showCheckingMessage(target) {
    const { message } = this.getTargetData(target);
    const text = target === INPUT_TARGET_BRANCH ? __('branch name') : __('source');

    this.removeMessage(target);
    message.classList.add('gl-text-gray-600');
    message.textContent = sprintf(__('Checking %{text} availability…'), { text });
    message.style.display = 'inline-block';
  }

  showNotAvailableMessage(target, validationType = VALIDATION_TYPE_BRANCH_UNAVAILABLE) {
    const { input, message } = this.getTargetData(target);
    const text = getValidationError(target, input, validationType);

    this.removeMessage(target);
    input.classList.add('gl-field-error-outline');
    message.classList.add('gl-text-red-500');
    message.textContent = text;
    message.style.display = 'inline-block';
  }

  updateBranchName(suggestedBranchName) {
    this.branchNameInput.value = suggestedBranchName;
    this.updateInputState(INPUT_TARGET_BRANCH, suggestedBranchName, '');
  }

  updateInputState(target, ref, result) {
    // target - 'branch' or 'ref' - which the input field we are searching a ref for.
    // ref - string - what a user typed.
    // result - string - what has been found on backend.
    if (target === INPUT_TARGET_BRANCH) this.updateTargetBranchInput(ref, result);
    if (target === INPUT_TARGET_REF) this.updateRefInput(ref, result);

    if (this.inputsAreValid()) {
      this.enable();
    } else {
      this.disableCreateAction();
    }
  }

  updateRefInput(ref, result) {
    this.sourceRefInput.dataset.value = ref;
    if (ref === result) {
      this.refIsValid = true;
      this.showAvailableMessage(INPUT_TARGET_REF);
    } else {
      this.refIsValid = false;
      this.sourceRefInput.dataset.value = ref;
      this.disableCreateAction();
      this.showNotAvailableMessage(INPUT_TARGET_REF);

      // Show ref hint.
      if (result) {
        this.sourceRefInput.value = result;
        this.sourceRefInput.setSelectionRange(ref.length, result.length);
      }
    }
  }

  updateTargetBranchInput(ref, result) {
    const branchNameErrors = findInvalidBranchNameCharacters(ref);
    const isInvalidString = branchNameErrors.length;
    if (ref !== result && !isInvalidString) {
      this.branchIsValid = true;
      // If a found branch equals exact the same text a user typed,
      // Or user typed input contains invalid chars,
      // that means a new branch cannot be created as it already exists.
      this.showAvailableMessage(INPUT_TARGET_BRANCH, VALIDATION_TYPE_BRANCH_UNAVAILABLE);
    } else if (isInvalidString) {
      this.branchIsValid = false;
      this.showNotAvailableMessage(INPUT_TARGET_BRANCH, VALIDATION_TYPE_INVALID_CHARS);
    } else {
      this.branchIsValid = false;
      this.showNotAvailableMessage(INPUT_TARGET_BRANCH);
    }
  }
}
