import { find } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import AccessDropdown from '~/projects/settings/access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export default class ProtectedBranchEdit {
  constructor(options) {
    this.hasLicense = options.hasLicense;

    this.$wraps = {};
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
    this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');
    this.$forcePushToggle = this.$wrap.find('.js-force-push-toggle');
    this.$codeOwnerToggle = this.$wrap.find('.js-code-owner-toggle');

    this.$wraps[ACCESS_LEVELS.MERGE] = this.$allowedToMergeDropdown.closest(
      `.${ACCESS_LEVELS.MERGE}-container`,
    );
    this.$wraps[ACCESS_LEVELS.PUSH] = this.$allowedToPushDropdown.closest(
      `.${ACCESS_LEVELS.PUSH}-container`,
    );

    this.buildDropdowns();
    this.bindEvents();
  }

  bindEvents() {
    this.$forcePushToggle.on('click', this.onForcePushToggleClick.bind(this));
    if (this.hasLicense) {
      this.$codeOwnerToggle.on('click', this.onCodeOwnerToggleClick.bind(this));
    }
  }

  onForcePushToggleClick() {
    this.$forcePushToggle.toggleClass('is-checked');
    this.$forcePushToggle.prop('disabled', true);

    const formData = {
      allow_force_push: this.$forcePushToggle.hasClass('is-checked'),
    };

    this.updateProtectedBranch(formData, () => this.$forcePushToggle.prop('disabled', false));
  }

  onCodeOwnerToggleClick() {
    this.$codeOwnerToggle.toggleClass('is-checked');
    this.$codeOwnerToggle.prop('disabled', true);

    const formData = {
      code_owner_approval_required: this.$codeOwnerToggle.hasClass('is-checked'),
    };

    this.updateProtectedBranch(formData, () => this.$codeOwnerToggle.prop('disabled', false));
  }

  updateProtectedBranch(formData, callback) {
    axios
      .patch(this.$wrap.data('url'), {
        protected_branch: formData,
      })
      .then(callback)
      .catch(() => {
        createFlash({ message: __('Failed to update branch!') });
      });
  }

  buildDropdowns() {
    // Allowed to merge dropdown
    this[`${ACCESS_LEVELS.MERGE}_dropdown`] = new AccessDropdown({
      accessLevel: ACCESS_LEVELS.MERGE,
      accessLevelsData: gon.merge_access_levels,
      $dropdown: this.$allowedToMergeDropdown,
      onSelect: this.onSelectOption.bind(this),
      onHide: this.onDropdownHide.bind(this),
      hasLicense: this.hasLicense,
    });

    // Allowed to push dropdown
    this[`${ACCESS_LEVELS.PUSH}_dropdown`] = new AccessDropdown({
      accessLevel: ACCESS_LEVELS.PUSH,
      accessLevelsData: gon.push_access_levels,
      $dropdown: this.$allowedToPushDropdown,
      onSelect: this.onSelectOption.bind(this),
      onHide: this.onDropdownHide.bind(this),
      hasLicense: this.hasLicense,
    });
  }

  onSelectOption() {
    this.hasChanges = true;
  }

  onDropdownHide() {
    if (!this.hasChanges) {
      return;
    }

    this.hasChanges = true;
    this.updatePermissions();
  }

  updatePermissions() {
    const formData = Object.keys(ACCESS_LEVELS).reduce((acc, level) => {
      const accessLevelName = ACCESS_LEVELS[level];
      const inputData = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
      acc[`${accessLevelName}_attributes`] = inputData;

      return acc;
    }, {});

    axios
      .patch(this.$wrap.data('url'), {
        protected_branch: formData,
      })
      .then(({ data }) => {
        this.hasChanges = false;

        Object.keys(ACCESS_LEVELS).forEach((level) => {
          const accessLevelName = ACCESS_LEVELS[level];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(data[accessLevelName], `${accessLevelName}_dropdown`);
        });
        this.$allowedToMergeDropdown.enable();
        this.$allowedToPushDropdown.enable();
      })
      .catch(() => {
        this.$allowedToMergeDropdown.enable();
        this.$allowedToPushDropdown.enable();
        createFlash({ message: __('Failed to update branch!') });
      });
  }

  setSelectedItemsToDropdown(items = [], dropdownName) {
    const itemsToAdd = items.map((currentItem) => {
      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this[dropdownName].getSelectedItems();
        const currentSelectedItem = find(selectedItems, {
          user_id: currentItem.user_id,
        });

        return {
          id: currentItem.id,
          user_id: currentItem.user_id,
          type: LEVEL_TYPES.USER,
          persisted: true,
          name: currentSelectedItem.name,
          username: currentSelectedItem.username,
          avatar_url: currentSelectedItem.avatar_url,
        };
      } else if (currentItem.group_id) {
        return {
          id: currentItem.id,
          group_id: currentItem.group_id,
          type: LEVEL_TYPES.GROUP,
          persisted: true,
        };
      }

      return {
        id: currentItem.id,
        access_level: currentItem.access_level,
        type: LEVEL_TYPES.ROLE,
        persisted: true,
      };
    });

    this[dropdownName].setSelectedItems(itemsToAdd);
  }
}
