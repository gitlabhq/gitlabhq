/* eslint-disable no-new, arrow-parens, no-param-reassign, comma-dangle, guard-for-in, no-restricted-syntax, max-len */
/* global ProtectedBranchDropdown */
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

  gl.ProtectedBranchCreate = class {
    constructor() {
      this.$wrap = this.$form = $('.js-new-protected-branch');
      this.buildDropdowns();
      this.$branchInput = this.$wrap.find('input[name="protected_branch[name]"]');
      this.bindEvents();
    }

    bindEvents() {
      this.$form.on('submit', this.onFormSubmit.bind(this));
    }

    buildDropdowns() {
      const $allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
      const $allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

      // Cache callback
      this.onSelectCallback = this.onSelect.bind(this);

      // Allowed to Merge dropdown
      this[`${ACCESS_LEVELS.MERGE}_dropdown`] = new gl.ProtectedBranchAccessDropdown({
        $dropdown: $allowedToMergeDropdown,
        accessLevelsData: gon.merge_access_levels,
        onSelect: this.onSelectCallback,
        accessLevel: ACCESS_LEVELS.MERGE
      });

      // Allowed to Push dropdown
      this[`${ACCESS_LEVELS.PUSH}_dropdown`] = new gl.ProtectedBranchAccessDropdown({
        $dropdown: $allowedToPushDropdown,
        accessLevelsData: gon.push_access_levels,
        onSelect: this.onSelectCallback,
        accessLevel: ACCESS_LEVELS.PUSH
      });

      // Protected branch dropdown
      new window.ProtectedBranchDropdown({
        $dropdown: this.$wrap.find('.js-protected-branch-select'),
        onSelect: this.onSelectCallback
      });
    }

    // Enable submit button after selecting an option
    onSelect() {
      const $allowedToMerge = this[`${ACCESS_LEVELS.MERGE}_dropdown`].getSelectedItems();
      const $allowedToPush = this[`${ACCESS_LEVELS.PUSH}_dropdown`].getSelectedItems();
      const toggle = !(this.$wrap.find('input[name="protected_branch[name]"]').val() && $allowedToMerge.length && $allowedToPush.length);

      this.$form.find('input[type="submit"]').attr('disabled', toggle);
    }

    getFormData() {
      const formData = {
        authenticity_token: this.$form.find('input[name="authenticity_token"]').val(),
        protected_branch: {
          name: this.$wrap.find('input[name="protected_branch[name]"]').val(),
        }
      };

      for (const ACCESS_LEVEL in ACCESS_LEVELS) {
        const selectedItems = this[`${ACCESS_LEVELS[ACCESS_LEVEL]}_dropdown`].getSelectedItems();
        const levelAttributes = [];

        for (let i = 0; i < selectedItems.length; i += 1) {
          const current = selectedItems[i];

          if (current.type === LEVEL_TYPES.USER) {
            levelAttributes.push({
              user_id: selectedItems[i].user_id
            });
          } else if (current.type === LEVEL_TYPES.ROLE) {
            levelAttributes.push({
              access_level: selectedItems[i].access_level
            });
          } else if (current.type === LEVEL_TYPES.GROUP) {
            levelAttributes.push({
              group_id: selectedItems[i].group_id
            });
          }
        }

        formData.protected_branch[`${ACCESS_LEVELS[ACCESS_LEVEL]}_attributes`] = levelAttributes;
      }

      return formData;
    }

    onFormSubmit(e) {
      e.preventDefault();

      $.ajax({
        url: this.$form.attr('action'),
        method: this.$form.attr('method'),
        data: this.getFormData()
      })
      .success(() => {
        location.reload();
      })
      .fail(() => {
        new Flash('Failed to protect the branch');
      });
    }
  };
})(window);
