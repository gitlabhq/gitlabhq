(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchEdit = class {
    constructor(options) {
      this.hasChanges = false;
      this.$wrap = options.$wrap;
      this.$allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
      this.$allowedToMergeDropdownWrap = this.$allowedToMergeDropdown.parents().eq(1);
      this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');
      this.$allowedToPushDropdownWrap = this.$allowedToPushDropdown.parents().eq(1);

      this.buildDropdowns();

      // Save initial state
      this.state = {
        merge: this.getMergeAccessLevelsAttributes(),
        push: this.getPushAccessLevelsAttributes()
      };
    }

    buildDropdowns() {
      // Allowed to merge dropdown
      new gl.allowedToMergeDropdown({
        $dropdown: this.$allowedToMergeDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this),
      });

      // Allowed to push dropdown
      new gl.allowedToPushDropdown({
        $dropdown: this.$allowedToPushDropdown,
        onSelect: this.onSelectOption.bind(this),
        onHide: this.onDropdownHide.bind(this)
      });
    }

    onSelectOption(item, $el) {
      this.hasChanges = true;
    }

    onDropdownHide() {
      if (!this.hasChanges) return;

      this.hasChanges = true;

      this.updatePermissions();
    }

    updatePermissions() {

      let merge = this.consolidateMergeData();
      let push = this.getPushAccessLevelsAttributes();

      return $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          id: this.$wrap.data('banchId'),
          protected_branch: {
            merge_access_levels_attributes: merge,
            push_access_levels_attributes: push
          }
        },
        success: (response) => {
          this.$wrap.effect('highlight');
          this.hasChanges = false;

          // Update State
          this.state.merge = response.merge_access_levels.map((access) => {
            if (access.user_id) {
              return {
                id: access.id,
                user_id: access.user_id,
              };
            } else {
              return {
                id: access.id,
                access_level: access.access_level,
              };
            }
          });
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update branch!');
        }
      });
    }

    consolidateMergeData() {
      // State takes precedence
      let mergeData = [];
      let mergeInputsData = this.getMergeAccessLevelsAttributes()

      for (var i = 0; i < mergeInputsData.length; i++) {
        let inState;
        let adding;
        var userId = parseInt(mergeInputsData[i].user_id);

        if (userId) {
          adding = 'user';
          inState = _.findWhere(this.state.merge, {user_id: userId});
        } else {
          adding = 'role';
          inState = _.findWhere(this.state.merge, {access_level: parseInt(mergeInputsData[i].access_level)});
        }


        if (inState) {
          mergeData.push(inState);
        } else {
          if (adding === 'user') {
            mergeData.push({
              user_id: parseInt(mergeInputsData[i].user_id)
            });
          } else if (adding === 'role') {
            mergeData.push({
              access_level: parseInt(mergeInputsData[i].access_level)
            });
          }

        }
      }

      return mergeData;
    }

    getMergeAccessLevelsAttributes() {
      let accessLevels = [];

      this.$allowedToMergeDropdownWrap
        .find('input[name^="protected_branch[merge_access_levels_attributes]"]')
        .map((i, el) => {
          const $el = $(el);
          const type = $el.data('type');
          const value = parseInt($el.val());
          const id = parseInt($el.data('id'));
          let obj = {};

          if (type === 'role') {
            obj.access_level = value
          } else if (type === 'user') {
            obj.user_id = value;
          }

          if (id) obj.id = id;

          accessLevels.push(obj);
        });

      return accessLevels;
    }

    getPushAccessLevelsAttributes() {
      let accessLevels = [];

      this.$allowedToPushDropdownWrap
        .find('input[name^="protected_branch[push_access_levels_attributes]"]')
        .map((i, el) => {
          const $el = $(el);
          const type = $el.data('type');
          const value = $el.val();

          if (type === 'role') {
            accessLevels.push({
              access_level: value
            });
          } else if (type === 'user') {
            accessLevels.push({
              user_id: value
            });
          }
        });

      return accessLevels;
    }
  }

})(window);
