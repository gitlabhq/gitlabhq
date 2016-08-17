/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class allowedToMergeDropdown extends gl.ProtectedBranchAccessDropdown {
    fieldName(selectedItem) {
      // Role by default
      let fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][access_level]`;

      if (selectedItem.type === 'user') {
        fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][user_id]`;
      }

      return fieldName;
    }
  }

  global.gl.allowedToMergeDropdown = allowedToMergeDropdown;

})(window);
