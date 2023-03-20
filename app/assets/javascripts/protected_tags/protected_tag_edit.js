import { find } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES, FAILED_TO_UPDATE_TAG_MESSAGE } from './constants';

export default class ProtectedTagEdit {
  constructor(options) {
    this.hasLicense = options.hasLicense;
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
    this.protectedTagAccessDropdown = new AccessDropdown({
      accessLevel: ACCESS_LEVELS.CREATE,
      accessLevelsData: gon.create_access_levels,
      $dropdown: this.$allowedToCreateDropdownButton,
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
      const inputData = this.protectedTagAccessDropdown.getInputData(accessLevelName);
      acc[`${accessLevelName}_attributes`] = inputData;

      return acc;
    }, {});

    axios
      .patch(this.$wrap.data('url'), {
        protected_tag: formData,
      })
      .then(({ data }) => {
        this.hasChanges = false;

        Object.keys(ACCESS_LEVELS).forEach((level) => {
          const accessLevelName = ACCESS_LEVELS[level];

          // The data coming from server will be the new persisted *state* for each dropdown
          this.setSelectedItemsToDropdown(data[accessLevelName], `${accessLevelName}_dropdown`);
        });
      })
      .catch(() => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
        createAlert({
          message: FAILED_TO_UPDATE_TAG_MESSAGE,
        });
      });
  }

  setSelectedItemsToDropdown(items = []) {
    const itemsToAdd = items.map((currentItem) => {
      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this.protectedTagAccessDropdown.getSelectedItems();
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

    this.protectedTagAccessDropdown.setSelectedItems(itemsToAdd);
  }
}
