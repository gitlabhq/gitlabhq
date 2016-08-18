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
    }

    buildDropdowns() {
      // Allowed to merge dropdown
      new gl.allowedToMergeDropdown({
        $dropdown: this.$allowedToMergeDropdown,
        onSelect: this.onSelect.bind(this),
        onHide: this.onHide.bind(this),
      });

      // Allowed to push dropdown
      new gl.allowedToPushDropdown({
        $dropdown: this.$allowedToPushDropdown,
        onSelect: this.onSelect.bind(this),
        onHide: this.onHide.bind(this)
      });
    }

    onSelect() {
      this.hasChanges = true;
    }

    onHide() {
      if (!this.hasChanges) {
        return;
      }

      this.hasChanges = true;

      const $allowedToMergeInput = this.$wrap.find(`input[name="${this.$allowedToMergeDropdown.data('fieldName')}"]`);
      const $allowedToPushInput = this.$wrap.find(`input[name="${this.$allowedToPushDropdown.data('fieldName')}"]`);

      let $mergeInputs = this.$allowedToMergeDropdownWrap.find('input[name^="protected_branch[merge_access_levels_attributes]"]')
      let $pushInputs = this.$allowedToPushDropdownWrap.find('input[name^="protected_branch[push_access_levels_attributes]"]')
      let merge_access_levels_attributes = [];
      let push_access_levels_attributes = [];

      $mergeInputs.map((i, el) => {
        const $el = $(el);
        const type = $el.data('type');
        const value = $el.val();


        if (type === 'role') {
          merge_access_levels_attributes.push({
            access_level: value
          });
        } else if (type === 'user') {
          merge_access_levels_attributes.push({
            user_id: value
          });
        }
      });

      $pushInputs.map((i, el) => {
        const $el = $(el);
        const type = $el.data('type');
        const value = $el.val();


        if (type === 'role') {
          push_access_levels_attributes.push({
            access_level: value
          });
        } else if (type === 'user') {
          push_access_levels_attributes.push({
            user_id: value
          });
        }
      });

      $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          id: this.$wrap.data('banchId'),
          protected_branch: {
            merge_access_levels_attributes,
            push_access_levels_attributes
          }
        },
        success: () => {
          this.$wrap.effect('highlight');
          this.hasChanges = false;
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update branch!');
        }
      });
    }
  }

})(window);
