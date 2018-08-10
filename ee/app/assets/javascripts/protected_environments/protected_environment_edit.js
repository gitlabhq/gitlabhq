import $ from 'jquery';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import Flash from '~/flash';
import AccessDropdown from 'ee/projects/settings/access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export default class ProtectedEnvironmentEdit {
  constructor(options) {
    this.$wraps = {};
    this.hasChanges = false;
    this.$wrap = options.$wrap;
    this.$allowedToDeployDropdown = this.$wrap.find('.js-allowed-to-deploy');

    this.$wraps[ACCESS_LEVELS.DEPLOY] = this.$allowedToDeployDropdown.closest(
      `.${ACCESS_LEVELS.DEPLOY}-container`,
    );

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to deploy dropdown
    this[`${ACCESS_LEVELS.DEPLOY}_dropdown`] = new AccessDropdown({
      accessLevel: ACCESS_LEVELS.deploy,
      accessLevelsData: gon.deploy_access_levels,
      $dropdown: this.$allowedToDeployDropdown,
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
      const accessLevelName = ACCESS_LEVELS[level];
      const inputData = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
      acc[`${accessLevelName}_attributes`] = inputData;

      return acc;
    }, {});

    axios
      .patch(this.$wrap.data('url'), {
        protected_environment: formData,
      })
      .then(({ data }) => {
        this.hasChanges = false;

        Object.keys(ACCESS_LEVELS).forEach(level => {
          const accessLevelName = ACCESS_LEVELS[level];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(data[accessLevelName], `${accessLevelName}_dropdown`);
        });
        this.$allowedToDeployDropdown.enable();
      })
      .catch(() => {
        this.$allowedToDeployDropdown.enable();
        Flash('Failed to update environment!', null, $('.js-protected-environments-list'));
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
