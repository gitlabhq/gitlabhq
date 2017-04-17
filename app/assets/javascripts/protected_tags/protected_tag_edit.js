/* eslint-disable no-new, guard-for-in, no-restricted-syntax */
/* global Flash */

import { ACCESS_LEVELS, LEVEL_TYPES } from './';
import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';

export default class ProtectedTagEdit {
  constructor(options) {
    this.$wrap = {};
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToCreateDropdownButton = this.$wrap.find('.js-allowed-to-create');

    this.$wraps[ACCESS_LEVELS.CREATE] = this.$allowedToCreateDropdown.closest(`.${ACCESS_LEVELS.CREATE}-container`);

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to create dropdown
    this[`${ACCESS_LEVELS.CREATE}_dropdown`] = new ProtectedTagAccessDropdown({
      accessLevel: ACCESS_LEVELS.CREATE,
      accessLevelsData: gon.create_access_levels,
      $dropdown: this.$allowedToCreateDropdownButton,
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
    const formData = {};

    for (const ACCESS_LEVEL in ACCESS_LEVELS) {
      const accessLevelName = ACCESS_LEVELS[ACCESS_LEVEL];

      formData[`${accessLevelName}_attributes`] = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
    }

    return $.ajax({
      type: 'POST',
      url: this.$wrap.data('url'),
      dataType: 'json',
      data: {
        _method: 'PATCH',
        protected_tag: formData,
      },
      success: (response) => {
        this.hasChanges = false;

        for (const ACCESS_LEVEL in ACCESS_LEVELS) {
          const accessLevelName = ACCESS_LEVELS[ACCESS_LEVEL];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(response[accessLevelName], `${accessLevelName}_dropdown`);
        }
      },
      error() {
        $.scrollTo(0);
        new Flash('Failed to update tag!');
      },
    }).always(() => {
      this.$allowedToCreateDropdownButton.enable();
    });
  }

  setSelectedItemsToDropdown(items = [], dropdownName) {
    const itemsToAdd = [];

    for (let i = 0; i < items.length; i += 1) {
      let itemToAdd;
      const currentItem = items[i];

      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this[dropdownName].getSelectedItems();
        const currentSelectedItem = _.findWhere(selectedItems, { user_id: currentItem.user_id });

        itemToAdd = {
          id: currentItem.id,
          user_id: currentItem.user_id,
          type: LEVEL_TYPES.USER,
          persisted: true,
          name: currentSelectedItem.name,
          username: currentSelectedItem.username,
          avatar_url: currentSelectedItem.avatar_url,
        };
      } else if (currentItem.group_id) {
        itemToAdd = {
          id: currentItem.id,
          group_id: currentItem.group_id,
          type: LEVEL_TYPES.GROUP,
          persisted: true,
        };
      } else {
        itemToAdd = {
          id: currentItem.id,
          access_level: currentItem.access_level,
          type: LEVEL_TYPES.ROLE,
          persisted: true,
        };
      }

      itemsToAdd.push(itemToAdd);
    }

    this[dropdownName].setSelectedItems(itemsToAdd);
  }
}
