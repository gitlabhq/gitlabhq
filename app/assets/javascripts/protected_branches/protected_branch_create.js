import $ from 'jquery';
import CreateItemDropdown from '~/create_item_dropdown';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import { initToggle } from '~/toggles';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import { initAccessDropdown } from '~/projects/settings/init_access_dropdown';
import {
  BRANCH_RULES_ANCHOR,
  PROTECTED_BRANCHES_ANCHOR,
  IS_PROTECTED_BRANCH_CREATED,
  ACCESS_LEVELS,
} from './constants';

export default class ProtectedBranchCreate {
  constructor(options) {
    this.hasLicense = options.hasLicense;
    this.$form = $('.js-new-protected-branch');
    this.isLocalStorageAvailable = AccessorUtilities.canUseLocalStorage();
    this.forcePushToggle = initToggle(document.querySelector('.js-force-push-toggle'));
    this.sectionSelector = options.sectionSelector;
    if (this.hasLicense) {
      this.codeOwnerToggle = initToggle(document.querySelector('.js-code-owner-toggle'));
    }

    this.selectedItems = {
      [ACCESS_LEVELS.PUSH]: [],
      [ACCESS_LEVELS.MERGE]: [],
    };
    this.initDropdowns();

    this.showSuccessAlertIfNeeded();
    this.bindEvents();
  }

  bindEvents() {
    this.$form.on('submit', this.onFormSubmit.bind(this));
  }

  initDropdowns() {
    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Merge dropdown
    const allowedToMergeSelector = 'js-allowed-to-merge';
    this[`${ACCESS_LEVELS.MERGE}_dropdown`] = this.buildDropdown({
      selector: allowedToMergeSelector,
      accessLevel: ACCESS_LEVELS.MERGE,
      accessLevelsData: gon.merge_access_levels,
      testId: 'allowed-to-merge-dropdown',
    });

    // Allowed to Push dropdown
    const allowedToPushSelector = 'js-allowed-to-push';
    this[`${ACCESS_LEVELS.PUSH}_dropdown`] = this.buildDropdown({
      selector: allowedToPushSelector,
      accessLevel: ACCESS_LEVELS.PUSH,
      accessLevelsData: gon.push_access_levels,
      testId: 'allowed-to-push-dropdown',
    });

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: this.$form.find('.js-protected-branch-select'),
      defaultToggleLabel: __('Protected Branch'),
      fieldName: 'protected_branch[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedBranchCreate.getProtectedBranches,
    });
  }

  buildDropdown({ selector, accessLevel, accessLevelsData, testId }) {
    const [el] = this.$form.find(`.${selector}`);
    if (!el) return undefined;

    const projectId = gon.current_project_id;
    const dropdown = initAccessDropdown(el, {
      toggleClass: `${selector} gl-form-input-lg`,
      hasLicense: this.hasLicense,
      searchEnabled: el.dataset.filter !== undefined,
      showUsers: projectId !== undefined,
      block: true,
      accessLevel,
      accessLevelsData,
      groupsWithProjectAccess: true,
      testId,
      sectionSelector: this.sectionSelector,
    });

    dropdown.$on('select', (selected) => {
      this.selectedItems[accessLevel] = selected;
      this.onSelectCallback();
    });

    dropdown.$on('shown', () => {
      this.createItemDropdown.close();
    });

    return dropdown;
  }

  // Enable submit button after selecting an option
  onSelect() {
    const toggle = !(
      this.$form.find('input[name="protected_branch[name]"]').val() &&
      this.selectedItems[ACCESS_LEVELS.MERGE].length &&
      this.selectedItems[ACCESS_LEVELS.PUSH].length
    );

    this.$form.find('button[type="submit"]').attr('disabled', toggle);
  }

  static getProtectedBranches(term, callback) {
    callback(gon.open_branches);
  }

  // eslint-disable-next-line class-methods-use-this
  expandAndScroll(anchor) {
    expandSection(anchor);
    scrollToElement(anchor);
  }

  hasProtectedBranchSuccessAlert() {
    return this.isLocalStorageAvailable && localStorage.getItem(IS_PROTECTED_BRANCH_CREATED);
  }

  createSuccessAlert() {
    if (!gon.features.editBranchRules) {
      this.alert = createAlert({
        variant: VARIANT_SUCCESS,
        containerSelector: '.js-alert-protected-branch-created-container',
        title: s__('ProtectedBranch|View protected branches as branch rules'),
        message: s__(
          'ProtectedBranch|Manage branch related settings in one area with branch rules.',
        ),
        primaryButton: {
          text: s__('ProtectedBranch|View branch rule'),
          clickHandler: () => this.expandAndScroll(BRANCH_RULES_ANCHOR),
        },
        secondaryButton: {
          text: __('Dismiss'),
          clickHandler: () => this.alert.dismiss(),
        },
      });
    }
  }

  createLimitedSuccessAlert() {
    this.alert = createAlert({
      variant: VARIANT_SUCCESS,
      containerSelector: '.js-alert-protected-branch-created-container',
      message: s__('ProtectedBranch|Protected branch was successfully created'),
    });
  }

  showSuccessAlertIfNeeded() {
    if (!this.hasProtectedBranchSuccessAlert()) {
      return;
    }
    this.expandAndScroll(PROTECTED_BRANCHES_ANCHOR);

    if (gon.abilities.adminProject || gon.abilities.adminGroup) {
      this.createSuccessAlert();
    } else {
      this.createLimitedSuccessAlert();
    }

    localStorage.removeItem(IS_PROTECTED_BRANCH_CREATED);
  }

  getFormData() {
    const formData = {
      authenticity_token: this.$form.find('input[name="authenticity_token"]').val(),
      protected_branch: {
        name: this.$form.find('input[name="protected_branch[name]"]').val(),
        allow_force_push: this.forcePushToggle.value,
        code_owner_approval_required: this.codeOwnerToggle?.value ?? false,
      },
    };

    Object.values(ACCESS_LEVELS).forEach((level) => {
      formData.protected_branch[`${level}_attributes`] = this.selectedItems[level];
    });

    return formData;
  }

  onFormSubmit(e) {
    e.preventDefault();

    axios[this.$form.attr('method')](this.$form.attr('action'), this.getFormData())
      .then(() => {
        if (this.isLocalStorageAvailable) {
          localStorage.setItem(IS_PROTECTED_BRANCH_CREATED, 'true');
        }
        window.location.reload();
      })
      .catch(() =>
        createAlert({
          message: __('Failed to protect the branch'),
        }),
      );
  }
}
