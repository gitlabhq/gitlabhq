/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class allowedToPushDropdown extends gl.ProtectedBranchAccessDropdown {
    fieldName(selectedItem) {
      // Role by default
      let fieldName = `protected_branch[push_access_levels_attributes][${this.inputCount}][access_level]`;

      if (selectedItem.type === 'user') {
        fieldName = `protected_branch[push_access_levels_attributes][${this.inputCount}][user_id]`;
      }

      return fieldName;
    }
  }

  global.gl.allowedToPushDropdown = allowedToPushDropdown;

})(window);
