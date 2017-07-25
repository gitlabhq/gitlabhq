/* eslint-disable no-new */
/* global Flash */

import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';
import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';

export default class ProtectedTagEdit {
  constructor(options) {
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToCreateDropdownButton = this.$wrap.find('.js-allowed-to-create');

    this.$allowedToCreateDropdownContainer = this.$allowedToCreateDropdownButton.closest('.create_access_levels-container');

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
    const formData = Object.keys(ACCESS_LEVELS).reduce((acc, level) => {
      /* eslint-disable no-param-reassign */
      const accessLevelName = ACCESS_LEVELS[level];
      const inputData = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
      acc[`${accessLevelName}_attributes`] = inputData;

      return acc;
    }, {});

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

        Object.keys(ACCESS_LEVELS).forEach((level) => {
          const accessLevelName = ACCESS_LEVELS[level];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(response[accessLevelName], `${accessLevelName}_dropdown`);
        });
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
