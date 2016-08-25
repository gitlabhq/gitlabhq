(global => {
  global.gl = global.gl || {};

  const LEVEL_TYPES = {
    USER: 'user',
    ROLE: 'role',
  };

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

      // Save initial state with existing dropdowns
      this.state = {};
      for (let ACCESS_LEVEL in ACCESS_LEVELS) {
        this.state[`${ACCESS_LEVELS[ACCESS_LEVEL]}_attributes`] = this.getAccessLevelDataFromInputs(ACCESS_LEVEL);
      }
    }

    buildDropdowns() {
      // Allowed to merge dropdown
      new gl.AllowedToMergeDropdown({
        accessLevel: ACCESS_LEVELS.MERGE,
        accessLevelsData: gon.merge_access_levels,
        $dropdown: this.$allowedToMergeDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this)
      });

      // Allowed to push dropdown
      new gl.AllowedToPushDropdown({
        accessLevel: ACCESS_LEVELS.PUSH,
        accessLevelsData: gon.push_access_levels,
        $dropdown: this.$allowedToPushDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this)
      });
    }

    onSelectOption(item, $el, dropdownInstance) {
      this.hasChanges = true;
      let itemToDestroy;
      let accessLevelState = this.state[`${dropdownInstance.accessLevel}_attributes`];

      // If element is not active it means it has been active
      if (!$el.is('.is-active')) {
        // We need to know if the selected item was already saved
        // if so we need to append the `_destroy` property
        // in order to delete it from the database

        // Retrieve the full data of the item we just selected
        if (item.type === LEVEL_TYPES.USER) {
          itemToDestroy = _.findWhere(accessLevelState, { user_id: item.id });
        } else if (item.type === LEVEL_TYPES.ROLE) {
          itemToDestroy = _.findWhere(accessLevelState, { access_level: item.id });
        }

        // State updated by reference
        itemToDestroy['_destroy'] = 1;
      }
    }

    onDropdownHide() {
      if (!this.hasChanges) return;

<<<<<<< HEAD
      this.hasChanges = true;

      this.updatePermissions();
    }

    updatePermissions() {
      let formData = {};

      for (let ACCESS_LEVEL in ACCESS_LEVELS) {
        formData[`${ACCESS_LEVELS[ACCESS_LEVEL]}_attributes`] = this.consolidateAccessLevelData(ACCESS_LEVEL);
      }

      return $.ajax({
=======
      // Do not update if one dropdown has not selected any option
      if (!($allowedToMergeInput.length && $allowedToPushInput.length)) return; 

      $.ajax({
>>>>>>> b2bf01f4c271be66e93ed6f4b48a1da4d50e558d
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

          // Update State
          for (let ACCESS_LEVEL in ACCESS_LEVELS) {
            let accessLevel = ACCESS_LEVELS[ACCESS_LEVEL];

            this.state[`${accessLevel}_attributes`] = [];

            for (let i = 0; i < response[accessLevel].length; i++) {
              let access = response[accessLevel][i];
              let accessData = {};

              if (access.user_id) {
                accessData = {
                  id: access.id,
                  user_id: access.user_id,
                };
              } else {
                accessData ={
                  id: access.id,
                  access_level: access.access_level,
                };
              }

              this.state[`${accessLevel}_attributes`].push(accessData);
            }
          }
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update branch!');
        }
      });
    }

    consolidateAccessLevelData(accessLevelKey) {
      // State takes precedence
      let accessLevel = ACCESS_LEVELS[accessLevelKey];
      let accessLevelData = [];
      let dataFromInputs = this.getAccessLevelDataFromInputs(accessLevelKey);

      // Collect and format items that will be sent to the server
      for (let i = 0; i < dataFromInputs.length; i++) {
        let inState;
        let adding;
        var userId = parseInt(dataFromInputs[i].user_id);

        // Inputs give us the *state* of the dropdown on the frontend before it's persisted
        // so we need to compare them with the persisted state which can be get or set on this.state
        if (userId) {
          adding = LEVEL_TYPES.USER;
          inState = _.findWhere(this.state[`${accessLevel}_attributes`], { user_id: userId });
        } else {
          adding = LEVEL_TYPES.ROLE;
          inState = _.findWhere(this.state[`${accessLevel}_attributes`], { access_level: parseInt(dataFromInputs[i].access_level) });
        }

        if (inState) {
          // collect item if it's already saved
          accessLevelData.push(inState);
        } else {
          // format item according the level type
          if (adding === LEVEL_TYPES.USER) {
            accessLevelData.push({
              user_id: parseInt(dataFromInputs[i].user_id)
            });
          } else if (adding === LEVEL_TYPES.ROLE) {
            accessLevelData.push({
              access_level: parseInt(dataFromInputs[i].access_level)
            });
          }
        }
      }

      // Since we didn't considered inputs that were removed
      // (because they are not present in the DOM anymore)
      // We can get them from the state
      this.state[`${accessLevel}_attributes`].forEach((item) => {
        if (item._destroy) {
          accessLevelData.push(item);
        }
      });

      return accessLevelData;
    }

    getAccessLevelDataFromInputs(accessLevelKey) {
      let accessLevels = [];
      let accessLevel = ACCESS_LEVELS[accessLevelKey];
      this.$wraps[accessLevel]
        .find(`input[name^="protected_branch[${accessLevel}_attributes]"]`)
        .map((i, el) => {
          const $el = $(el);
          const type = $el.data('type');
          const value = parseInt($el.val());
          const id = parseInt($el.data('id'));
          let obj = {};

          if (type === LEVEL_TYPES.ROLE) {
            obj.access_level = value
          } else if (type === LEVEL_TYPES.USER) {
            obj.user_id = value;
          }

          if (id) obj.id = id;

          accessLevels.push(obj);
        });

      return accessLevels;
    }
  }

})(window);
