/* eslint-disable no-new */

import $ from 'jquery';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import Flash from '~/flash';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';
import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';

export default class ProtectedBranchEdit {
  constructor(options) {
    this.$wraps = {};
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
    this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

    this.$wraps[ACCESS_LEVELS.MERGE] = this.$allowedToMergeDropdown.closest(`.${ACCESS_LEVELS.MERGE}-container`);
    this.$wraps[ACCESS_LEVELS.PUSH] = this.$allowedToPushDropdown.closest(`.${ACCESS_LEVELS.PUSH}-container`);

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to merge dropdown
    this[`${ACCESS_LEVELS.MERGE}_dropdown`] = new ProtectedBranchAccessDropdown({
      accessLevel: ACCESS_LEVELS.MERGE,
      accessLevelsData: gon.merge_access_levels,
      $dropdown: this.$allowedToMergeDropdown,
      onSelect: this.onSelectOption.bind(this),
      onHide: this.onDropdownHide.bind(this),
    });

    // Allowed to push dropdown
    this[`${ACCESS_LEVELS.PUSH}_dropdown`] = new ProtectedBranchAccessDropdown({
      accessLevel: ACCESS_LEVELS.PUSH,
      accessLevelsData: gon.push_access_levels,
      $dropdown: this.$allowedToPushDropdown,
      onSelect: this.onSelectOption.bind(this),
      onHide: this.onDropdownHide.bind(this),
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
      /* eslint-disable no-param-reassign */
      const accessLevelName = ACCESS_LEVELS[level];
      const inputData = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
      acc[`${accessLevelName}_attributes`] = inputData;

      return acc;
    }, {});

    axios.patch(this.$wrap.data('url'), {
      protected_branch: formData,
    }).then(({ data }) => {
      this.hasChanges = false;

      Object.keys(ACCESS_LEVELS).forEach((level) => {
        const accessLevelName = ACCESS_LEVELS[level];

        // The data coming from server will be the new persisted *state* for each dropdown
        this.setSelectedItemsToDropdown(data[accessLevelName], `${accessLevelName}_dropdown`);
      });
      this.$allowedToMergeDropdown.enable();
      this.$allowedToPushDropdown.enable();
    }).catch(() => {
      this.$allowedToMergeDropdown.enable();
      this.$allowedToPushDropdown.enable();
      Flash('Failed to update branch!', null, $('.js-protected-branches-list'));
    });
  }

  setSelectedItemsToDropdown(items = [], dropdownName) {
    const itemsToAdd = items.map((currentItem) => {
      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this[dropdownName].getSelectedItems();
        const currentSelectedItem = _.findWhere(selectedItems, { user_id: currentItem.user_id });

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
