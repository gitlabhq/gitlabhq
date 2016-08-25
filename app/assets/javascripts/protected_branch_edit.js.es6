(global => {
  global.gl = global.gl || {};

  const ACCESS_LEVELS = {
    MERGE: 'merge_access_levels',
    PUSH: 'push_access_levels',
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
      let formData = {};

      for (let ACCESS_LEVEL in ACCESS_LEVELS) {
        let accessLevelName = ACCESS_LEVELS[ACCESS_LEVEL];

        formData[`${accessLevelName}_attributes`] = this[`${accessLevelName}_dropdown`].getInputData(accessLevelName);
      }

      return $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          id: this.$wrap.data('banchId'),
          protected_branch: formData
        },
        success: (response) => {
          this.$wrap.effect('highlight');
          this.hasChanges = false;

          for (let ACCESS_LEVEL in ACCESS_LEVELS) {
            let accessLevelName = ACCESS_LEVELS[ACCESS_LEVEL];

            // The data coming from server will be the new persisted *state* for each dropdown
            this.setSelectedItemsToDropdown(response[accessLevelName], `${accessLevelName}_dropdown`);
          }
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update branch!');
        }
      });
    }

    setSelectedItemsToDropdown(items = [], dropdownName) {
      let itemsToAdd = [];

      for (let i = 0; i < items.length; i++) {
        let itemToAdd;
        let currentItem = items[i];

        if (currentItem.user_id) {
          // Solo haciendo esto solo para usuarios por ahora
          // obtenemos la data más actual de los items seleccionados
          let selectedItems = this[dropdownName].getSelectedItems();
          let currentSelectedItem = _.findWhere(selectedItems, { user_id: currentItem.user_id });

          itemToAdd = {
            id: currentItem.id,
            user_id: currentItem.user_id,
            type: 'user',
            persisted: true,
            name: currentSelectedItem.name,
            username: currentSelectedItem.username,
            avatar_url: currentSelectedItem.avatar_url
          }
        } else {
          itemToAdd = {
            id: currentItem.id,
            access_level: currentItem.access_level,
            type: 'role',
            persisted: true
          }
        }

        itemsToAdd.push(itemToAdd);
      }

      this[dropdownName].setSelectedItems(itemsToAdd);
    }
  }
})(window);
