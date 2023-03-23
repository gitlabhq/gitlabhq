import $ from 'jquery';
import CreateItemDropdown from '~/create_item_dropdown';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import AccessDropdown from '~/projects/settings/access_dropdown';
import { initToggle } from '~/toggles';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import {
  BRANCH_RULES_ANCHOR,
  PROTECTED_BRANCHES_ANCHOR,
  IS_PROTECTED_BRANCH_CREATED,
  ACCESS_LEVELS,
  LEVEL_TYPES,
} from './constants';

export default class ProtectedBranchCreate {
  constructor(options) {
    this.hasLicense = options.hasLicense;
    this.$form = $('.js-new-protected-branch');
    this.isLocalStorageAvailable = AccessorUtilities.canUseLocalStorage();
    this.currentProjectUserDefaults = {};
    this.buildDropdowns();

    this.forcePushToggle = initToggle(document.querySelector('.js-force-push-toggle'));

    if (this.hasLicense) {
      this.codeOwnerToggle = initToggle(document.querySelector('.js-code-owner-toggle'));
    }
    this.showSuccessAlertIfNeeded();
    this.bindEvents();
  }

  bindEvents() {
    this.$form.on('submit', this.onFormSubmit.bind(this));
  }

  buildDropdowns() {
    const $allowedToMergeDropdown = this.$form.find('.js-allowed-to-merge');
    const $allowedToPushDropdown = this.$form.find('.js-allowed-to-push');

    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Merge dropdown
    this[`${ACCESS_LEVELS.MERGE}_dropdown`] = new AccessDropdown({
      $dropdown: $allowedToMergeDropdown,
      accessLevelsData: gon.merge_access_levels,
      onSelect: this.onSelectCallback,
      accessLevel: ACCESS_LEVELS.MERGE,
      hasLicense: this.hasLicense,
    });

    // Allowed to Push dropdown
    this[`${ACCESS_LEVELS.PUSH}_dropdown`] = new AccessDropdown({
      $dropdown: $allowedToPushDropdown,
      accessLevelsData: gon.push_access_levels,
      onSelect: this.onSelectCallback,
      accessLevel: ACCESS_LEVELS.PUSH,
      hasLicense: this.hasLicense,
    });

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: this.$form.find('.js-protected-branch-select'),
      defaultToggleLabel: __('Protected Branch'),
      fieldName: 'protected_branch[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedBranchCreate.getProtectedBranches,
    });
  }

  // Enable submit button after selecting an option
  onSelect() {
    const $allowedToMerge = this[`${ACCESS_LEVELS.MERGE}_dropdown`].getSelectedItems();
    const $allowedToPush = this[`${ACCESS_LEVELS.PUSH}_dropdown`].getSelectedItems();
    const toggle = !(
      this.$form.find('input[name="protected_branch[name]"]').val() &&
      $allowedToMerge.length &&
      $allowedToPush.length
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
    return (
      window.gon?.features?.branchRules &&
      this.isLocalStorageAvailable &&
      localStorage.getItem(IS_PROTECTED_BRANCH_CREATED)
    );
  }

  createSuccessAlert() {
    this.alert = createAlert({
      variant: VARIANT_SUCCESS,
      containerSelector: '.js-alert-protected-branch-created-container',
      title: s__('ProtectedBranch|View protected branches as branch rules'),
      message: s__('ProtectedBranch|Manage branch related settings in one area with branch rules.'),
      primaryButton: {
        text: s__('ProtectedBranch|View branch rule'),
        clickHandler: () => {
          this.expandAndScroll(BRANCH_RULES_ANCHOR);
        },
      },
      secondaryButton: {
        text: __('Dismiss'),
        clickHandler: () => this.alert.dismiss(),
      },
    });
  }

  showSuccessAlertIfNeeded() {
    if (!this.hasProtectedBranchSuccessAlert()) {
      return;
    }
    this.expandAndScroll(PROTECTED_BRANCHES_ANCHOR);

    this.createSuccessAlert();
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

    Object.keys(ACCESS_LEVELS).forEach((level) => {
      const accessLevel = ACCESS_LEVELS[level];
      const selectedItems = this[`${accessLevel}_dropdown`].getSelectedItems();
      const levelAttributes = [];

      selectedItems.forEach((item) => {
        if (item.type === LEVEL_TYPES.USER) {
          levelAttributes.push({
            user_id: item.user_id,
          });
        } else if (item.type === LEVEL_TYPES.ROLE) {
          levelAttributes.push({
            access_level: item.access_level,
          });
        } else if (item.type === LEVEL_TYPES.GROUP) {
          levelAttributes.push({
            group_id: item.group_id,
          });
        } else if (item.type === LEVEL_TYPES.DEPLOY_KEY) {
          levelAttributes.push({
            deploy_key_id: item.deploy_key_id,
          });
        }
      });

      formData.protected_branch[`${accessLevel}_attributes`] = levelAttributes;
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
