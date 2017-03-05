/* eslint-disable no-new, arrow-parens, no-param-reassign, comma-dangle, dot-notation, no-unused-vars, no-restricted-syntax, guard-for-in, max-len */
/* global Flash */

(global => {
  global.gl = global.gl || {};

  const ACCESS_LEVELS = {
    MERGE: 'merge_access_levels',
    PUSH: 'push_access_levels',
  };

  const LEVEL_TYPES = {
    ROLE: 'role',
    USER: 'user',
    GROUP: 'group'
  };

  gl.ProtectedBranchEdit = class {
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
      this['merge_access_levels_dropdown'] = new gl.ProtectedBranchAccessDropdown({
        accessLevel: ACCESS_LEVELS.MERGE,
        accessLevelsData: gon.merge_access_levels,
        $dropdown: this.$allowedToMergeDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this)
      });

      // Allowed to push dropdown
      this['push_access_levels_dropdown'] = new gl.ProtectedBranchAccessDropdown({
        accessLevel: ACCESS_LEVELS.PUSH,
        accessLevelsData: gon.push_access_levels,
        $dropdown: this.$allowedToPushDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this)
      });
    }

    onSelectOption(item, $el, dropdownInstance) {
      this.hasChanges = true;
    }

    onDropdownHide() {
      if (!this.hasChanges) return;

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
          protected_branch: formData
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
          new Flash('Failed to update branch!');
        }
      }).always(() => {
        this.$allowedToMergeDropdown.enable();
        this.$allowedToPushDropdown.enable();
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
            avatar_url: currentSelectedItem.avatar_url
          };
        } else if (currentItem.group_id) {
          itemToAdd = {
            id: currentItem.id,
            group_id: currentItem.group_id,
            type: LEVEL_TYPES.GROUP,
            persisted: true
          };
        } else {
          itemToAdd = {
            id: currentItem.id,
            access_level: currentItem.access_level,
            type: LEVEL_TYPES.ROLE,
            persisted: true
          };
        }

        itemsToAdd.push(itemToAdd);
      }

      this[dropdownName].setSelectedItems(itemsToAdd);
    }
  };
})(window);
