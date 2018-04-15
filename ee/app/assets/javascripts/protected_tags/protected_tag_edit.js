/* eslint-disable no-new */

import $ from 'jquery';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import AccessDropdown from 'ee/projects/settings/access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export default class ProtectedTagEdit {
  constructor(options) {
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToCreateDropdownButton = this.$wrap.find('.js-allowed-to-create');

    this.$allowedToCreateDropdownContainer = this.$allowedToCreateDropdownButton.closest(
      '.create_access_levels-container',
    );

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to create dropdown
    this[`${ACCESS_LEVELS.CREATE}_dropdown`] = new AccessDropdown({
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

    axios
      .patch(this.$wrap.data('url'), {
        protected_tag: formData,
      })
      .then(({ data }) => {
        this.hasChanges = false;

        Object.keys(ACCESS_LEVELS).forEach(level => {
          const accessLevelName = ACCESS_LEVELS[level];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(data[accessLevelName], `${accessLevelName}_dropdown`);
        });
      })
      .catch(() => {
        $.scrollTo(0);
        createFlash(s__('ProjectSettings|Failed to update tag!'));
      });
  }

  setSelectedItemsToDropdown(items = [], dropdownName) {
    const itemsToAdd = items.map(currentItem => {
      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this[dropdownName].getSelectedItems();
        const currentSelectedItem = _.findWhere(selectedItems, {
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
